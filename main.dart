import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const PhotoboothApp());
}

class PhotoboothApp extends StatelessWidget {
  const PhotoboothApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const Layar1Utama(),
    );
  }
}

// --- LAYAR 1: UTAMA ---
class Layar1Utama extends StatelessWidget {
  const Layar1Utama({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_enhance, size: 100, color: Colors.blue), // Ganti dengan Image.asset(logo)
            const Text("PHOTOBOOTH PEKALONGAN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Layar2PilihFrame())),
              icon: const Icon(Icons.play_arrow),
              label: const Text("START"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          ],
        ),
      ),
    );
  }
}

// --- LAYAR 2: PILIH FRAME ---
class Layar2PilihFrame extends StatefulWidget {
  const Layar2PilihFrame({super.key});
  @override
  State<Layar2PilihFrame> createState() => _Layar2PilihFrameState();
}

class _Layar2PilihFrameState extends State<Layar2PilihFrame> {
  int frameTerpilih = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Frame")),
      body: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => setState(() => frameTerpilih = 1),
                  child: Container(
                    width: 150, height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: frameTerpilih == 1 ? Colors.blue : Colors.grey, width: 4),
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    child: const Center(child: Text("Frame 1\n(2 Foto)")),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => frameTerpilih = 2),
                  child: Container(
                    width: 150, height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: frameTerpilih == 2 ? Colors.blue : Colors.grey, width: 4),
                      color: Colors.green.withOpacity(0.1),
                    ),
                    child: const Center(child: Text("Frame 2\n(4 Foto)")),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Layar3SesiFoto(frameId: frameTerpilih))),
              child: const Text("MULAI SESI FOTO"),
            ),
          )
        ],
      ),
    );
  }
}

// --- LAYAR 3: SESI FOTO ---
class Layar3SesiFoto extends StatefulWidget {
  final int frameId;
  const Layar3SesiFoto({super.key, required this.frameId});
  @override
  State<Layar3SesiFoto> createState() => _Layar3SesiFotoState();
}

class _Layar3SesiFotoState extends State<Layar3SesiFoto> {
  CameraController? _controller;
  List<String> hasilFoto = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    _controller!.initialize().then((_) => setState(() {}));
  }

  Future<void> jepret() async {
    final foto = await _controller!.takePicture();
    setState(() => hasilFoto.add(foto.path));
    
    // Logika otomatis pindah jika jumlah foto sudah sesuai frame
    int target = widget.frameId == 1 ? 2 : 4;
    if (hasilFoto.length >= target) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Layar4Hasil(images: hasilFoto, frameId: widget.frameId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) return const Scaffold();
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.topRight,
            child: Text("Foto ke: ${hasilFoto.length + 1}", style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(onPressed: jepret, child: const Icon(Icons.camera_alt)),
          )
        ],
      ),
    );
  }
}

// --- LAYAR 4: HASIL (REVIEW, QR, PRINT) ---
class Layar4Hasil extends StatelessWidget {
  final List<String> images;
  final int frameId;
  const Layar4Hasil({super.key, required this.images, required this.frameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hasil Akhir")),
      body: Center(
        child: Column(
          children: [
            // Preview Gabungan (Simulasi Frame)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              width: 250,
              child: Column(
                children: images.map((path) => Image.file(File(path), height: 100)).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("RETAKE")),
                ElevatedButton(
                  onPressed: () {
                    showDialog(context: context, builder: (c) => AlertDialog(
                      content: QrImageView(data: "Link_Foto_ID_123", size: 200),
                    ));
                  }, 
                  child: const Text("QR CODE")
                ),
                ElevatedButton(onPressed: () {}, child: const Text("PRINT")),
              ],
            ),
            const Spacer(),
            ElevatedButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text("SELESAI")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}