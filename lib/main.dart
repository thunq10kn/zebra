import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:another_brother/custom_paper.dart';
import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart';
import 'package:another_brother/type_b_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final controller = PageController(initialPage: 1);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Another Brother Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: QlBluetoothPrintPage(title: 'QL-820NWB Bluetooth Sample'));
  }
}

class QlBluetoothPrintPage extends StatefulWidget {
  QlBluetoothPrintPage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _QlBluetoothPrintPageState createState() => _QlBluetoothPrintPageState();
}

class _QlBluetoothPrintPageState extends State<QlBluetoothPrintPage> {
  int countter = 0;
  String scannedData = "";
  String buffer = "";
  String deviceName = "QL-820NWB";
  bool isPrinting = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  FocusNode focusNode = FocusNode();

  Future<void> _playAudio() async {
    await _stopAudio();
    await _audioPlayer.play(AssetSource('tut_tut.mp3'));
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      String key = event.data.logicalKey.keyLabel;

      if (key.isNotEmpty && key != 'Enter') {
        buffer += key;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() {
          scannedData = buffer;
          incrementCounter();
          buffer = "";
        });
      }
    }
  }

  void incrementCounter() {
    setState(() {
      if (countter < 40) {
        _playAudio();
        countter++;

      }
    });
  }

  void printRecord(BuildContext context) async {
    if (isPrinting == true) return;
    setState(() {
      isPrinting = true;
    });
    if (!await Permission.storage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Access to storage is needed in order print."),
        ),
      ));
      return;
    }

    var printer = new Printer();
    var printInfo = PrinterInfo();
    printInfo.printerModel = Model.QL_820NWB;
    printInfo.printMode = PrintMode.FIT_TO_PAGE;
    printInfo.isAutoCut = true;
    printInfo.port = Port.BLUETOOTH;
    // Set the label type.
    printInfo.labelNameIndex = QL700.ordinalFromID(QL700.W62RB.getId());

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printInfo);

    // Get a list of printers with my model available in the network.
    List<BluetoothPrinter> printers =
        await printer.getBluetoothPrinters([Model.QL_820NWB.getName()]);

    log("Found ${printers.length} printers with model ${Model.QL_820NWB.getName()}");
    if (printers.isEmpty) {
      // Show a message if no printers are found.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("No paired printers found on your device."),
        ),
      ));

      return;
    }
    // Get the IP Address from the first printer found.
    printInfo.macAddress = printers.single.macAddress;
    log("printers.single.macAddress = ${printers.single.macAddress}");
    printer.setPrinterInfo(printInfo);
    PrinterStatus status =
        await printer.printText(buildParagraph("Counter = $countter"));
    log("statussss = ${status}");
    setState(() {
      isPrinting = false;
    });
  }

  ui.Paragraph buildParagraph(String text) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 16,
        height: 1.5,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
      ..addText(text);

    final paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 200));
    return paragraph;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ---------- PHẦN TIÊU ĐỀ ----------
                Container(
                  color: const Color(0xFF2F4EB2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 15, color: Colors.red),
                          SizedBox(width: 6),
                          Text(
                            '梱包指示あり   12SKU  6160Pcs',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                      Text(
                        'カートン No 101   SKU検品数   作業完了',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),

                // ---------- NỘI DUNG GIỮA ----------
                Expanded(
                  child: Container(
                    color: countter == 40 ? Colors.cyan : Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '箱検品数',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$countter/40',
                          style: TextStyle(
                              fontSize: 160,
                              fontWeight: FontWeight.bold,
                              color: countter == 40
                                  ? Colors.yellowAccent
                                  : Colors.black),
                        ),
                        const SizedBox(height: 8),
                        RawKeyboardListener(
                          focusNode: focusNode,
                          autofocus: true,
                          onKey: _handleKey,
                          child: Center(
                            child: Text(scannedData),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),

                // ---------- CÁC NÚT DƯỚI ----------
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 10,
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(
                            fontSize: 20, color: Colors.black87),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Expanded(child: _buildButton(context, '中断')),
                          const SizedBox(height: 5),
                          Expanded(
                            child: _buildButton(
                              context,
                              'やり直し',
                              onTap: () {
                                log("DMSDMLSMDLSKMDMLD");
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: _buildButton(
                          context,
                          'ラベル発行',
                          onTap: () {
                            printRecord(context);
                          },
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: _buildButton(context, '実績照会', onTap: () {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Visibility(child: Container(
              color: Colors.black87,
              child: const Center(
                child: Stack(
                  children: [
                    Center(child: Text(
                      "通信中です\nしばらくお待ちください",
                      style: TextStyle(color: Colors.grey, fontSize: 30),
                    ),),
                    Center(
                      child: SizedBox(
                        width: 100,height: 100,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),visible: isPrinting,)
          ],
        ),
      ),
    );
  }

  static Widget _buildButton(
    BuildContext context,
    String text, {
    Function? onTap,
  }) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2F4EB2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2), // Đổ bóng nhẹ phía dưới
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          onTap?.call();
        },
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<ui.Image> loadImage(String assetPath) async {
    final ByteData img = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(img.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}
