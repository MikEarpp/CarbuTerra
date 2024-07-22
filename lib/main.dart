import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: constant_identifier_names
enum EnumString { CarbuTerra, consumption, price, fuelType, calculations, saveHistory, fuel, euro, earthEurope, route, Ok }

void main() => runApp(const CarbuTerraApp());

class CarbuTerraApp extends StatelessWidget {
  const CarbuTerraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: EnumString.CarbuTerra.name,
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      themeMode: ThemeMode.system,
      home: const CarbuTerraHomePage(),
      debugShowCheckedModeBanner: false);
}

class CarbuTerraHomePage extends StatefulWidget {
  const CarbuTerraHomePage({super.key});

  @override
  CarbuTerraHomePageState createState() => CarbuTerraHomePageState();
}

class CarbuTerraHomePageState extends State<CarbuTerraHomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _budgetController = TextEditingController(text: "100");
  final TextEditingController _consumptionController = TextEditingController(text: "3.9");
  final TextEditingController _kmParcourueController = TextEditingController(text: "100");
  final TextEditingController _litresController = TextEditingController(text: "45");
  final TextEditingController _priceController = TextEditingController(text: "1.999");
  final List<String> _unities = ["km", "L", "€", "kg"];
  final List<String> _textString = ["Distance parcourue", "Volume utilisé", "Budget maximum", "Prix au litre"];
  static const List<String> _menuString = ["Préférences", "À propos"];
  final List<String> _buttons = ["Calculer", "Effacer"];
  final List<String> _fuelType = ["Diesel", "Essence", "SP 95 E10", "GPL", "Ethanol E85"];
  final List<double> _co2Factors = [2.67, 2.28, 2.21, 1.66, 1.61];
  static const double normalPadding = 16;
  double? _distanceTabTotalConsumption;
  double? _distanceTabTotalCost;
  double? _distanceTabCo2Emissions;
  double? _volumeTabDistanceWithLitres;
  double? _volumeTabCostForLitres;
  double? _volumeTabCo2Emissions;
  double? _budgetTabDistanceWithBudget;
  double? _budgetTabLitresForBudget;
  double? _budgetTabCo2Emissions;
  List<String> _calculations = [];
  String _selectedFuelType = "";
  late TabController _tabController;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _saveHistory = true;

  static Widget paddingThis(List<Widget> children) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: normalPadding, vertical: normalPadding / 2), child: Column(children: children));

  @override
  void initState() {
    super.initState();
    _selectedFuelType = _fuelType[0];
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_validateForm);
    _consumptionController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
    _kmParcourueController.addListener(_validateForm);
    _litresController.addListener(_validateForm);
    _budgetController.addListener(_validateForm);
    _init();
  }

  Future<void> _init() async => await _loadSavedData();

  @override
  void dispose() {
    _tabController.removeListener(_validateForm);
    _tabController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
    _kmParcourueController.dispose();
    _litresController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _consumptionController.text = prefs.getString(EnumString.consumption.name) ?? "3.9";
      _priceController.text = prefs.getString(EnumString.price.name) ?? "1.999";
      _selectedFuelType = prefs.getString(EnumString.fuelType.name) ?? _fuelType[0];
      _saveHistory = prefs.getBool(EnumString.saveHistory.name) ?? true;
      _calculations = _saveHistory ? prefs.getStringList(EnumString.calculations.name) ?? [] : [];
    });
    _validateForm();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(EnumString.consumption.name, _consumptionController.text);
    await prefs.setString(EnumString.price.name, _priceController.text);
    await prefs.setString(EnumString.fuelType.name, _selectedFuelType);
    await prefs.setBool(EnumString.saveHistory.name, _saveHistory);
    _saveHistory ? await prefs.setStringList(EnumString.calculations.name, _calculations) : prefs.remove(EnumString.calculations.name);
  }

  void _validateForm() => _isFormValid.value = _consumptionController.text.isNotEmpty &&
          double.tryParse(_consumptionController.text) != null &&
          double.tryParse(_consumptionController.text)! > 0 &&
          _priceController.text.isNotEmpty &&
          double.tryParse(_priceController.text) != null &&
          double.tryParse(_priceController.text)! > 0 &&
          _tabController.index == 0
      ? _kmParcourueController.text.isNotEmpty &&
          double.tryParse(_kmParcourueController.text) != null &&
          double.tryParse(_kmParcourueController.text)! > 0
      : _tabController.index == 1
          ? _litresController.text.isNotEmpty &&
              double.tryParse(_litresController.text) != null &&
              double.tryParse(_litresController.text)! > 0
          : _tabController.index == 2
              ? _budgetController.text.isNotEmpty &&
                  double.tryParse(_budgetController.text) != null &&
                  double.tryParse(_budgetController.text)! > 0
              : _calculations.isNotEmpty;

  String formatDouble(double value) {
    String formatted = value.toStringAsFixed(2);
    for (String suffix in [".00", ".0", "0"]) {
      if (formatted.endsWith(suffix)) {
        formatted = formatted.substring(0, formatted.length - suffix.length);
        break;
      }
    }
    final int integerPartEnd = formatted.contains(".") ? formatted.indexOf(".") : formatted.length;
    final String integerPart = formatted.substring(0, integerPartEnd);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(" ");
      }
      buffer.write(integerPart[i]);
    }
    return buffer.toString() + (formatted.contains(".") ? formatted.substring(integerPartEnd) : "");
  }

  double _getCo2EmissionFactor() => _co2Factors[_fuelType.contains(_selectedFuelType) ? _fuelType.indexOf(_selectedFuelType) : 0];

  void calculate() {
    FocusScope.of(context).unfocus();
    if (_tabController.index == 0) {
      final double kmParcourus = double.tryParse(_kmParcourueController.text) ?? 0;
      setState(() {
        _distanceTabTotalConsumption = kmParcourus * ((double.tryParse(_consumptionController.text) ?? 0) / 100);
        _distanceTabTotalCost = _distanceTabTotalConsumption! * (double.tryParse(_priceController.text) ?? 0);
        _distanceTabCo2Emissions = _distanceTabTotalConsumption! * _getCo2EmissionFactor();
        logThis(
            "$_selectedFuelType, ${formatDouble(kmParcourus)} ${_unities[0]}, ${formatDouble(_distanceTabTotalConsumption!)} ${_unities[1]}, ${formatDouble(_distanceTabTotalCost!)} ${_unities[2]}, ${formatDouble(_distanceTabCo2Emissions!)} ${_unities[3]}");
      });
    } else if (_tabController.index == 1) {
      final double litres = double.tryParse(_litresController.text) ?? 0;
      setState(() {
        _volumeTabDistanceWithLitres = (litres / (double.tryParse(_consumptionController.text) ?? 0)) * 100;
        _volumeTabCostForLitres = litres * (double.tryParse(_priceController.text) ?? 0);
        _volumeTabCo2Emissions = litres * _getCo2EmissionFactor();
        logThis(
            "$_selectedFuelType, ${formatDouble(litres)} ${_unities[1]}, ${formatDouble(_volumeTabDistanceWithLitres!)} ${_unities[0]}, ${formatDouble(_volumeTabCostForLitres!)} ${_unities[2]}, ${formatDouble(_volumeTabCo2Emissions!)} ${_unities[3]}");
      });
    } else if (_tabController.index == 2) {
      final double budget = double.tryParse(_budgetController.text) ?? 0;
      setState(() {
        _budgetTabLitresForBudget = budget / (double.tryParse(_priceController.text) ?? 0);
        _budgetTabDistanceWithBudget = (_budgetTabLitresForBudget! / (double.tryParse(_consumptionController.text) ?? 0)) * 100;
        _budgetTabCo2Emissions = _budgetTabLitresForBudget! * _getCo2EmissionFactor();
        logThis(
            "$_selectedFuelType, ${formatDouble(budget)} ${_unities[2]}, ${formatDouble(_budgetTabDistanceWithBudget!)} ${_unities[0]}, ${formatDouble(_budgetTabLitresForBudget!)} ${_unities[1]}, ${formatDouble(_budgetTabCo2Emissions!)} ${_unities[3]}");
      });
    }
  }

  void _clearHistory() => setState(() {
        _calculations.clear();
        _saveData();
      });

  void logThis(String text) {
    if ((_calculations.isNotEmpty && _calculations.last != text) || _calculations.isEmpty) {
      _calculations.add(text);
      _saveData();
    }
  }

  Widget showResultLines(List<dynamic> data) {
    final List<Widget> obj = [];
    for (var i = 0; i < data.length; i += 2) {
      final Color color = i == 0
          ? Colors.red
          : i == 2
              ? Colors.green
              : Colors.blue;
      obj.add(SvgPicture.asset("assets/${data[i]}.svg", colorFilter: ColorFilter.mode(color, BlendMode.srcIn)));
      obj.add(Padding(
          padding: const EdgeInsets.only(top: normalPadding / 2, bottom: normalPadding * 2),
          child: Text(
              "${formatDouble(data[i + 1])} ${_unities[data[i] == EnumString.route.name ? 0 : data[i] == EnumString.fuel.name ? 1 : data[i] == EnumString.euro.name ? 2 : 3]}",
              style: TextStyle(color: color, fontSize: 22.0, fontWeight: FontWeight.bold))));
    }
    return Column(children: obj);
  }

  Widget tabContents(int tabIndex) => SingleChildScrollView(
      child: paddingThis([
            SizedBox(
              width: MediaQuery.of(context).size.width / 1.5,
              child: TextField(
                  controller: tabIndex == 0
                      ? _kmParcourueController
                      : tabIndex == 1
                          ? _litresController
                          : _budgetController,
                  decoration:
                      InputDecoration(labelText: "${_textString[tabIndex]} (${_unities[tabIndex]})", border: const OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
            const SizedBox(height: normalPadding),
            ValueListenableBuilder<bool>(
                valueListenable: _isFormValid,
                builder: (context, isValid, child) =>
                    ElevatedButton(onPressed: isValid ? () => calculate() : null, child: Text(_buttons[0]))),
            const SizedBox(height: normalPadding)
          ] +
          (tabIndex == 0 && _distanceTabTotalCost != null && _distanceTabTotalConsumption != null && _distanceTabCo2Emissions != null
              ? [
                  showResultLines([
                    EnumString.fuel.name,
                    _distanceTabTotalConsumption!,
                    EnumString.euro.name,
                    _distanceTabTotalCost!,
                    EnumString.earthEurope.name,
                    _distanceTabCo2Emissions!
                  ])
                ]
              : tabIndex == 1 && _volumeTabDistanceWithLitres != null && _volumeTabCostForLitres != null && _volumeTabCo2Emissions != null
                  ? [
                      showResultLines([
                        EnumString.euro.name,
                        _volumeTabCostForLitres!,
                        EnumString.route.name,
                        _volumeTabDistanceWithLitres!,
                        EnumString.earthEurope.name,
                        _volumeTabCo2Emissions!
                      ])
                    ]
                  : tabIndex == 2 &&
                          _budgetTabDistanceWithBudget != null &&
                          _budgetTabLitresForBudget != null &&
                          _budgetTabCo2Emissions != null
                      ? [
                          showResultLines([
                            EnumString.fuel.name,
                            _budgetTabLitresForBudget!,
                            EnumString.route.name,
                            _budgetTabDistanceWithBudget!,
                            EnumString.earthEurope.name,
                            _budgetTabCo2Emissions!
                          ])
                        ]
                      : [])));

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 4,
      child: Scaffold(
          appBar: AppBar(title: Text(EnumString.CarbuTerra.name), actions: [
            PopupMenuButton<String>(
                onSelected: (value) {
                  value == _menuString[1]
                      ? showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) => AlertDialog(
                              title: Text("${EnumString.CarbuTerra.name} by MikEarpp\n1.0"),
                              content: const Text("Calculer les coûts, les distances et les émissions\n"
                                  "de CO2 liés à la consommation de carburant."),
                              actions: <Widget>[TextButton(child: Text(EnumString.Ok.name), onPressed: () => Navigator.of(context).pop())]))
                      : value == _menuString[0]
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsPage(
                                      saveHistory: _saveHistory,
                                      onSettingsChanged: (bool newSaveHistory) => setState(() {
                                            _saveHistory = newSaveHistory;
                                            _saveData();
                                          }))))
                          : null;
                },
                itemBuilder: (BuildContext context) =>
                    _menuString.map((String choice) => PopupMenuItem<String>(value: choice, child: Text(choice))).toList())
          ]),
          body: Column(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: normalPadding, vertical: normalPadding / 2),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          controller: _consumptionController,
                          decoration: InputDecoration(labelText: "${_unities[1]}/100 ${_unities[0]}", border: const OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,1}'))])),
                  const SizedBox(width: normalPadding / 2),
                  DropdownButton<String>(
                      value: _selectedFuelType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFuelType = newValue!;
                          _saveData();
                        });
                      },
                      items: _fuelType
                          .map<DropdownMenuItem<String>>(
                              (String value) => DropdownMenuItem<String>(value: value, child: Center(child: Text(value))))
                          .toList()),
                  const SizedBox(width: normalPadding / 2),
                  Expanded(
                      child: TextField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: "${_textString[3]} (${_unities[2]})", border: const OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,3}'))]))
                ])),
            TabBar(
                controller: _tabController,
                tabs: [..._textString.take(3), "Historique"]
                    .map((title) => Text(title, overflow: TextOverflow.ellipsis, softWrap: false))
                    .toList()),
            Expanded(
                child: TabBarView(controller: _tabController, children: [
              tabContents(0),
              tabContents(1),
              tabContents(2),
              paddingThis([
                ElevatedButton(onPressed: _calculations.isNotEmpty ? _clearHistory : null, child: Text(_buttons[1])),
                Expanded(
                    child: ListView.builder(
                        itemCount: _calculations.length,
                        itemBuilder: (context, index) => ListTile(
                            title: Text(_calculations[index]),
                            trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => setState(() {
                                      _calculations.removeAt(index);
                                      _saveData();
                                    })))))
              ])
            ]))
          ])));
}

class SettingsPage extends StatefulWidget {
  final bool saveHistory;
  final Function(bool) onSettingsChanged;

  const SettingsPage({super.key, required this.saveHistory, required this.onSettingsChanged});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late bool _saveHistory;

  @override
  void initState() {
    super.initState();
    _saveHistory = widget.saveHistory;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(CarbuTerraHomePageState._menuString[0])),
      body: CarbuTerraHomePageState.paddingThis([
        ListTile(
            title: SizedBox(width: MediaQuery.of(context).size.width / 2, child: const Text("Sauvegarder l'historique sur mobile?")),
            trailing: Switch(value: _saveHistory, onChanged: (bool value) => setState(() => _saveHistory = value))),
        ElevatedButton(
            onPressed: () {
              widget.onSettingsChanged(_saveHistory);
              Navigator.pop(context);
            },
            child: Text(EnumString.Ok.name))
      ]));
}
