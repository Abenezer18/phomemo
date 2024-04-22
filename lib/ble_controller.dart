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
  var isWritableCharacteristic = false.obs;
  RxBool isConnected = false.obs;
  RxBool isPrinting = false.obs;
  RxBool isConnecting = false.obs;
  RxBool isScanning = false.obs;

  Future<void> scanDevices() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        isScanning.value = true;
        await ble.startScan(timeout: const Duration(seconds: 5));
        ble.stopScan();
      }
    }
    isScanning.value = false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    isConnecting.value = true;
    await device.connect();
    this.device = device;
    _getServices();
    print('Connecting to ${device.name}');
    isConnected.value = true;
    isConnecting.value = false;
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
      if (!device.isNull) {
        print("not null");
      } else {
        print("null");
      }
      await device?.disconnect();
      print("Device Disconnected!");
      // Reset the device and services after disconnection
      device = null;
      services.clear();
      // Notify listeners about the change in connection state
      update();
    } catch (e) {
      print("Error disconnecting: $e");
    }
  }

  Future<void> write(List<int> data) async {
    if(isPrinting.isFalse){
      isPrinting = true.obs;
      if(isWritableCharacteristic.isTrue){
        print("writable!!!");
        try {
          await writableCharacteristic?.write(data);
          print('Data written successfully to characteristic ${writableCharacteristic?.uuid}');
          isPrinting = false.obs;
          return;
        } catch (e) {
          print('Error writing data to characteristic ${writableCharacteristic?.uuid}: $e');
        }
      }
      try {
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            try {
              await characteristic.write(data);
              print('Data written successfully to characteristic ${characteristic.uuid}');
              writableCharacteristic = characteristic;
              isWritableCharacteristic = true.obs;
              isPrinting = false.obs;
              return;
            } catch (e) {
              print('Error writing data to characteristic ${characteristic.uuid}: $e');
            }
          }
        }
        print('No characteristic found with write properties');
      } catch (e) {
        print('Error discovering services: $e');
      }
    }
    isPrinting = false.obs;
  }
}