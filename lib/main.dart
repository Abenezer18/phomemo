import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phomemo/phomemo.dart';

import 'ble_controller.dart';

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
                Obx(() =>
                Column(
                  children: [
                    Text(
                      controller.isScanning.isTrue
                          ? 'Scanning...'
                          : "...",
                    ),
                    Text(
                      controller.isConnecting.isTrue
                          ? 'Connecting...'
                          : "...",
                    ),
                    // Display connected device and its connection state
                    Text(
                      controller.device != null
                          ? 'Connected to: ${controller.device!.name}'
                          : 'No device connected',
                    ),
                    Text(
                      controller.device != null
                          ? 'Connection State: ${controller.isConnected.toString()}'
                          : '',
                    ),
                  ],
                )),
                SizedBox(height: 20),
                // Scanned devices list
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
                  onPressed: ()  {
                    controller.scanDevices();
                  },
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
            pickImageAndPrint(context); // Pass the context here
          }
        },
        tooltip: 'Print',
        child: const Icon(Icons.print),
      ),
    );
  }

  void pickImageAndPrint(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Phomemo phomemo = Phomemo(send: bleController.write);
      ByteData imageData = await pickedFile.readAsBytes().then((value) => ByteData.view(Uint8List.fromList(value).buffer));
      List<int> bytes = imageData.buffer.asUint8List();
      img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      if (!printing) {
        printing = true;
        await phomemo.printLabel(
          [image],
          printer: PhomemoPrinter.m220,
          labelSize: Size(30, 40),
        );
        printing = false;
      }
    } else {
      print('No image selected.');
    }
  }

}