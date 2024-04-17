import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';


class BleController extends GetxController {
  FlutterBlue ble = FlutterBlue.instance;

  Stream<List<ScanResult>> get scanResults => ble.scanResults;
  BluetoothDevice? device;
  List<BluetoothService> services = [];
  List<BluetoothCharacteristic>? characteristic;
  BluetoothCharacteristic? writableCharacteristic;

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        ble.startScan(timeout: const Duration(seconds: 10));
        ble.stopScan();
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    this.device = device;
    _getServices();
    print('Connecting to ${device.name}');
  }

  void _getServices() async {
    services = await device!.discoverServices();

    for(BluetoothService service in services){
      print(service.uuid);
    }
  }
  void disconnectDevice() async {
    try {
      print("Disconnecting...");
      if(!device.isNull){
        print("not null");
      } else {
        print("null");
      }
      await device?.disconnect();
      print("Device Disconnected!");
      // Reset the device and services after disconnection
      device = null;
      services.clear();
      // Optionally, you might want to reset other state variables related to the device
    } catch (e) {
      print("Error disconnecting: $e");
      // Handle the error gracefully, you might want to retry or show an error message
    }
  }

  void getBleData() {
    _readCharacteristic();
  }

  void _readCharacteristic() async{
    BluetoothCharacteristic? toSend;
    characteristic!.forEach((char) {
      if (char.properties.notify) {
        toSend = char;
      }
    });
    List<int> value = await toSend!.read();
  }

  Future<List<int>> read() async{
    BluetoothCharacteristic? toSend;
    characteristic!.forEach((char) {
      if (char.properties.notify) {
        toSend = char;
      }
    });
    return await toSend!.read();
  }

  Future<void> write(List<int> data) async {
    try {
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          try {
            await characteristic.write(data);
            print('Data written successfully to characteristic ${characteristic.uuid}');
            // If the write operation succeeds, this characteristic supports the write property
            writableCharacteristic = characteristic;
            return; // Exit the loop as we found a writable characteristic
          } catch (e) {
            print('Error writing data to characteristic ${characteristic.uuid}: $e');
          }
        }
      }
      // If no writable characteristic is found after iterating through all characteristics
      print(device?.name);
      print('No characteristic found with write properties');
    } catch (e) {
      print('Error discovering services: $e');
    }
  }

}