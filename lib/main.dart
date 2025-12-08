import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arıza Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UserFormPage(),
    );
  }
}

/* Local in-memory DB fallback when Firebase not available */
class LocalDB {
  static Map<String, List<String>> hospitals = {
    "Samsun Eğitim ve Araştırma Hastanesi": ["KVC YB", "Radyoloji"],
    "Ankara Şehir Hastanesi": ["Ameliyathane"],
  };

  static List<Map<String, dynamic>> records = [];

  static void addHospital(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    if (!hospitals.containsKey(n)) {
      hospitals[n] = [];
    }
  }

  static void addUnit(String hospitalName, String unit) {
    final h = hospitalName.trim();
    final u = unit.trim();
    if (h.isEmpty || u.isEmpty) return;
    if (!hospitals.containsKey(h)) hospitals[h] = [];
    if (!hospitals[h]!.contains(u)) {
      hospitals[h]!.add(u);
    }
  }
}

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});
  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  DateTime selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  String? selectedHospital;
  String? selectedUnit;

  final TextEditingController hospitalCtrl = TextEditingController();
  final TextEditingController unitCtrl = TextEditingController();
  final TextEditingController faultCtrl = TextEditingController();
  final TextEditingController serialCtrl = TextEditingController();

  bool isFault = false;
  bool isRepaired = false;
  bool _saving = false;

  Future<void> scanQR() async {
    try {
      final qr = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'İptal', true, ScanMode.QR);
      if (qr != '-1') setState(() => serialCtrl.text = qr);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR tarama başlatılamadı')));
    }
  }

  Future<void> saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // apply manual inputs
    if (hospitalCtrl.text.isNotEmpty) {
      selectedHospital = hospitalCtrl.text.trim();
      LocalDB.addHospital(selectedHospital!);
    }
    if (unitCtrl.text.isNotEmpty && selectedHospital != null) {
      selectedUnit = unitCtrl.text.trim();
      LocalDB.addUnit(selectedHospital!, selectedUnit!);
    }

    final data = {
      "hospital": selectedHospital ?? "",
      "unit": selectedUnit ?? "",
      "fault": faultCtrl.text,
      "serial": serialCtrl.text,
      "isFault": isFault,
      "isRepaired": isRepaired,
      "date": selectedDate.toIso8601String(),
      "createdAt": DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance.collection("reports").add(data);
    } catch (e) {
      LocalDB.records.add(data);
    }

    setState(() => _saving = false);

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kayıt oluşturuldu"))
    );

    clearForm();
  }

  void clearForm() {
    setState(() {
      selectedDate = DateTime.now();
      selectedHospital = null;
      selectedUnit = null;
      hospitalCtrl.clear();
      unitCtrl.clear();
      faultCtrl.clear();
      serialCtrl.clear();
      isFault = false;
      isRepaired = false;
    });
  }

  @override
  void dispose() {
    hospitalCtrl.dispose();
    unitCtrl.dispose();
    faultCtrl.dispose();
    serialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd.MM.yyyy").format(selectedDate);
    final hospitalList = LocalDB.hospitals.keys.toList();
    final unitList = selectedHospital == null ? [] : (LocalDB.hospitals[selectedHospital] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text("Türksoy M. - Yavuz Ö."), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Hastane", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownSearch<String>(
              items: hospitalList,
              selectedItem: selectedHospital,
              showSearchBox: true,
              onChanged: (v) {
                setState(() {
                  selectedHospital = v;
                  selectedUnit = null;
                  unitCtrl.clear();
                });
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Hastane seçin",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: hospitalCtrl,
              decoration: const InputDecoration(
                hintText: "Manuel hastane gir",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Birim", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownSearch<String>(
              items: unitList,
              selectedItem: selectedUnit,
              showSearchBox: true,
              onChanged: (v) => setState(() => selectedUnit = v),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Birim seçin",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: unitCtrl,
              decoration: const InputDecoration(
                hintText: "Manuel birim gir",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Tarih", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (d != null) setState(() => selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [Expanded(child: Text(dateStr)), const Icon(Icons.calendar_month)]),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Arıza Açıklaması", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(controller: faultCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Arıza açıklamasını yazın")),

            const SizedBox(height: 20),
            Row(children: [
              Checkbox(value: isFault, onChanged: (v) => setState(() => isFault = v ?? false)),
              const Text("Arıza"),
              const SizedBox(width: 20),
              Checkbox(value: isRepaired, onChanged: (v) => setState(() => isRepaired = v ?? false)),
              const Text("Tamir Edildi"),
            ]),
            const SizedBox(height: 20),

            const Text("Seri No / QR Kod"),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(controller: serialCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Seri numarası"))),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: scanQR, icon: const Icon(Icons.qr_code), label: const Text("Tara"))
            ]),

            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : saveRecord, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text("Kaydet"))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black87), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordsPage())), child: const Text("Kayıtlar"))),
          ]),
        ),
      ),
    );
  }
}

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = LocalDB.records.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıtlar")),
      body: items.isEmpty ? const Center(child: Text("Hiç kayıt yok")) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (_, i) {
        final r = items[i];
        return Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Hastane: ${r['hospital']}"),
          Text("Birim: ${r['unit']}"),
          Text("Seri: ${r['serial']}"),
          Text("Arıza: ${r['fault']}"),
          Text("Tarih: ${r['date']}"),
        ])));
      }),
    );
  }
}
