import Foundation
import AVFoundation

public final class VoiceBiometrics: @unchecked Sendable {
    public static let shared = VoiceBiometrics()
    public enum AuthResult: Sendable { case authenticated(score: Double), denied(score: Double), notTrained, error(String) }
    private var voiceprint: [Double]?
    private let threshold: Double = 0.72
    private let lock = NSLock()
    private let profilePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/MACRON/voiceprint.json")
    private init() { loadProfile() }
    public var isTrained: Bool { lock.lock(); defer { lock.unlock() }; return voiceprint != nil }
    public func train(with audioBuffer: AVAudioPCMBuffer, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let f = self.extractFeatures(from: audioBuffer) else { DispatchQueue.main.async { completion(false) }; return }
            self.lock.lock(); self.voiceprint = f; self.lock.unlock(); self.saveProfile(); DispatchQueue.main.async { completion(true) }
        }
    }
    public func authenticate(audioBuffer: AVAudioPCMBuffer, completion: @escaping (AuthResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.lock.lock(); guard let ref = self.voiceprint else { self.lock.unlock(); DispatchQueue.main.async { completion(.notTrained) }; return }; self.lock.unlock()
            guard let s = self.extractFeatures(from: audioBuffer) else { DispatchQueue.main.async { completion(.error("No se pudieron extraer features")) }; return }
            let score = self.cosineSimilarity(ref, s)
            DispatchQueue.main.async { completion(score >= self.threshold ? .authenticated(score: score) : .denied(score: score)) }
        }
    }
    public func authenticateFile(at url: URL, completion: @escaping (AuthResult) -> Void) {
        guard let file = try? AVAudioFile(forReading: url), let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { completion(.error("Archivo invalido")); return }
        do { try file.read(into: buf); authenticate(audioBuffer: buf, completion: completion) } catch { completion(.error(error.localizedDescription)) }
    }
    private func extractFeatures(from buffer: AVAudioPCMBuffer) -> [Double]? {
        guard let cd = buffer.floatChannelData?[0] else { return nil }
        let fl = Int(buffer.frameLength)
        var emp = [Double](repeating: 0, count: fl); emp[0] = Double(cd[0])
        for i in 1..<fl { emp[i] = Double(cd[i]) - 0.97 * Double(cd[i-1]) }
        let ws = 512, hs = 256; var frames: [[Double]] = []
        for start in stride(from: 0, to: fl - ws, by: hs) {
            var win = [Double](repeating: 0, count: ws)
            for i in 0..<ws { let h = 0.5 - 0.5 * cos(2.0 * .pi * Double(i) / Double(ws - 1)); win[i] = emp[start+i] * h }
            let N = ws
            var mag = [Double](repeating: 0, count: N/2)
            for k in 0..<N/2 {
                var re: Double = 0, im: Double = 0
                for n in 0..<N {
                    let angle = -2.0 * .pi * Double(k) * Double(n) / Double(N)
                    re += win[n] * cos(angle)
                    im += win[n] * sin(angle)
                }
                mag[k] = sqrt(re*re + im*im)
            }
            let mb = 13, sr = Double(buffer.format.sampleRate), nyq = sr/2.0; var mf = [Double](repeating: 0, count: mb)
            for b in 0..<mb {
                let fLow = melToHz(hzToMel(100.0) + Double(b)*(hzToMel(nyq)-hzToMel(100.0))/Double(mb))
                let fHigh = melToHz(hzToMel(100.0) + Double(b+1)*(hzToMel(nyq)-hzToMel(100.0))/Double(mb))
                let bl = Int(fLow/nyq*Double(N/2)), bh = Int(fHigh/nyq*Double(N/2)); var s: Double = 0
                for bin in max(0,bl)..<min(N/2,bh) { s += mag[bin] }
                mf[b] = log(max(s, 1e-10))
            }
            frames.append(mf)
        }
        guard !frames.isEmpty else { return nil }
        let nf = frames.count; var avg = [Double](repeating: 0, count: 13)
        for f in frames { for i in 0..<13 { avg[i] += f[i] } }
        for i in 0..<13 { avg[i] /= Double(nf) }
        let n = sqrt(avg.reduce(0){$0+$1*$1}); if n>0 { for i in 0..<13 { avg[i] /= n } }
        return avg
    }
    private func hzToMel(_ hz: Double) -> Double { 2595.0 * log10(1.0 + hz/700.0) }
    private func melToHz(_ mel: Double) -> Double { 700.0 * (pow(10.0, mel/2595.0) - 1.0) }
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }; var d: Double = 0, na: Double = 0, nb: Double = 0
        for i in 0..<a.count { d += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
        return d / (sqrt(na)*sqrt(nb))
    }
    private func saveProfile() { lock.lock(); defer { lock.unlock() }; guard let vp = voiceprint else { return }; let d: [String:Any] = ["voiceprint":vp,"version":1,"date":ISO8601DateFormatter().string(from:Date())]; if let data = try? JSONSerialization.data(withJSONObject: d) { try? data.write(to: profilePath) } }
    private func loadProfile() { guard let d = try? Data(contentsOf: profilePath), let dict = try? JSONSerialization.jsonObject(with: d) as? [String:Any], let vp = dict["voiceprint"] as? [Double] else { return }; voiceprint = vp }
    public func resetProfile() { lock.lock(); voiceprint = nil; lock.unlock(); try? FileManager.default.removeItem(at: profilePath) }
}
