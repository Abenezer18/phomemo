import 'dart:typed_data';

import 'package:blue/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:phomemo/phomemo.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BleController bleController = Get.put(BleController());
  bool printing = false;
  PhomemoHelper helper = PhomemoHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("yee"),
      ),


      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (BleController controller) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<List<ScanResult>>(
                  stream: controller.scanResults,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        height: 400,
                        width: 300,
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data![index];
                            return Card(
                              elevation: 2,
                              child: ListTile(
                                onTap: () {
                                  // Connect to the selected device
                                  controller.connectToDevice(data.device);
                                },
                                title: Text(data.device.name),
                                subtitle: Text(data.device.id.id),
                                trailing: Text(data.rssi.toString()),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return Center(child: Text("No Device"));
                    }
                  },
                ),
                SizedBox(height: 10,),
                ElevatedButton(
                  onPressed: () => controller.scanDevices(),
                  child: Text("SCAN"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => controller.disconnectDevice(),
                  child: Text("DISCONNECT"),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picker = ImagePicker();
          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            Uint8List? imageData = await pickedFile.readAsBytes();
            // printPhomemo(image: imageData, name: "sheeshgggggggggsoerthnjrfgnaeipgbagpbglabe");
            pickImageAndPrint(context); // Pass the context here
          }
        },
        tooltip: 'Print',
        child: const Icon(Icons.print),
      ),
    );
  }

  void pickImageAndPrint(BuildContext context) async {
    // Pick an image from the device's gallery or take a new photo with the camera
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Create an instance of Phomemo
      Phomemo phomemo = Phomemo(send: bleController.write);

      // Load and decode the selected image
      ByteData imageData = await pickedFile.readAsBytes().then((value) => ByteData.view(Uint8List.fromList(value).buffer));
      List<int> bytes = imageData.buffer.asUint8List();
      img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      // Print the image
      await phomemo.printLabel(
        [image], // Pass the image data as a list
        printer: PhomemoPrinter.m220, // Specify the printer type as M220
        labelSize: Size(30, 40), // Specify the label size
      );
    } else {
      // User canceled image selection
      print('No image selected.');
    }
  }

  Future<void> printPhomemo({Uint8List? image, String? name, Size? size}) async {
  if (printing) return;
  printing = true;
  Phomemo label = Phomemo(send: bleController.write, read: bleController.read);
  PhomemoHelper helper = PhomemoHelper();
  PhomemoPrinter printer = PhomemoPrinter.m220;

  if (printer == PhomemoPrinter.d35 && size!.width == double.infinity) {
    size = const Size(25, 12); // Default size if width is infinity
  }

  img.Image? letter = name != null
      ? await helper.generateImage(
    TextSpan(
      text: name,
      style: const TextStyle(
        fontFamily: 'MuseoSans',
        fontSize: 34,
        color: Colors.black,
      ),
    ),
    size: Size(10, 10),
  )
      : null;

  img.Image? qr = image != null ? img.decodePng(image) : null;

  if (label.send != null && label.printLabel != null) {
    await label.printLabel(
      [qr, letter],
      printer: printer,
      spacing: 5,
    ).then((value) {
      printing = false;
    }).catchError((error) {
      printing = false;
      // Handle error here
      print("Error printing: $error");
    });
  } else {
    printing = false;
  }
}
}
