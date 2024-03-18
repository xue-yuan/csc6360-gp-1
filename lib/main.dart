import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:flutter_custom_month_picker/flutter_custom_month_picker.dart';
import './database.dart' as db;
import './expense.dart' as expense;

void main() => runApp(const ExpenseTrackerApp());

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ExpenseTrackerHomePage(),
    );
  }
}

class ExpenseTrackerHomePage extends StatefulWidget {
  const ExpenseTrackerHomePage({super.key});

  @override
  State<ExpenseTrackerHomePage> createState() => _ExpenseTrackerHomePageState();
}

class _ExpenseTrackerHomePageState extends State<ExpenseTrackerHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = ['Food', 'Shopping', 'Transport', 'Bills'];
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final db.DatabaseHelper _dbHelper = db.DatabaseHelper.instance;

  DateTime _expenseDate = DateTime.now();
  DateTime _reportDate = DateTime.now();
  DateTime _chartDate = DateTime.now();
  String _expenseCategory = 'Food';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showExpenseAddedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Expense Added'),
          content: const Text('Expense added successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Failed'),
          content: const Text('Expense added failed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _expenseDate) {
      setState(() {
        _expenseDate = pickedDate;
      });
    }
  }

  void _addExpense(BuildContext context, String name, String amountText,
      String category) async {
    double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      return;
    }
    expense.Expense e = expense.Expense(
      id: -1,
      name: name,
      amount: amount,
      category: category,
      date:
          "${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}",
    );

    await _dbHelper.insertExpense(e.toMap());

    setState(() {
      _amountController.clear();
      _nameController.clear();
      _expenseCategory = 'Food';
      _expenseDate = DateTime.now();
    });
  }

  void _saveExpense(int id, String name, String amountText, String category,
      DateTime date) async {
    double amount = double.tryParse(amountText) ?? 0.0;

    await _dbHelper.updateExpense(id, name, amount, category, date);
    await _dbHelper.getExpensesByDate(date);
    setState(() {});
  }

  void _updateExpense(expense.Expense expense) async {
    _showEditDialog(expense);
  }

  void _deleteExpense(expense.Expense expense) async {
    await _dbHelper.deleteExpenseById(expense.id);
    await _dbHelper.getExpensesByDate(DateTime.parse(expense.date));
    setState(() {});
  }

  Widget _buildPieChart() {
    return FutureBuilder<Map<String, double>>(
      future: _getExpenseCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text('No expenses.'));
        }

        return PieChart(
          dataMap: snapshot.data!,
          animationDuration: const Duration(milliseconds: 800),
          chartLegendSpacing: 60,
          chartRadius: MediaQuery.of(context).size.width / 1.6,
          initialAngleInDegree: 90,
          chartType: ChartType.disc,
          legendOptions: const LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.bottom,
            showLegends: true,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          chartValuesOptions: const ChartValuesOptions(
            showChartValueBackground: true,
            showChartValues: true,
            showChartValuesInPercentage: true,
            showChartValuesOutside: true,
            chartValueStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20.0),
            decimalPlaces: 1,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expense name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      double? amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                    value: _expenseCategory,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _expenseCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Select Date:'),
                  const SizedBox(height: 8.0),
                  Text(
                    '${_expenseDate.year}-${_expenseDate.month}-${_expenseDate.day}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      _showDatePicker(context);
                    },
                    child: const Text('Choose Date'),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        if (_formKey.currentState!.validate()) {
                          _addExpense(context, _nameController.text,
                              _amountController.text, _expenseCategory);
                          _showExpenseAddedDialog(context);
                        }
                      } catch (e) {
                        _showExpenseErrorDialog(context);
                      }
                    },
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
          )),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 32.0),
                child: Row(
                  children: [
                    const Text('Pick Month:', style: TextStyle(fontSize: 16.0)),
                    const SizedBox(width: 16.0),
                    Text(
                      '${_chartDate.year}-${_chartDate.month}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(width: 32.0),
                    ElevatedButton(
                      onPressed: () {
                        showMonthPicker(
                          context,
                          onSelected: (month, year) {
                            setState(() {
                              _chartDate = DateTime(year, month);
                            });
                          },
                          highlightColor: Colors.purple,
                          textColor: Colors.white,
                        );
                      },
                      child: const Text('Pick Month'),
                    ),
                  ],
                )),
            const SizedBox(height: 80.0),
            Builder(
              builder: (context) {
                return _buildPieChart();
              },
            ),
          ]),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0.0, horizontal: 32.0),
                child: Row(
                  children: [
                    const Text('Pick Date:', style: TextStyle(fontSize: 16.0)),
                    const SizedBox(width: 16.0),
                    Text(
                      '${_reportDate.year}-${_reportDate.month}-${_reportDate.day}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(width: 32.0),
                    ElevatedButton(
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: _reportDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        ).then((selectedDate) {
                          if (selectedDate != null) {
                            setState(() {
                              _reportDate = selectedDate;
                            });
                          }
                        });
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<expense.Expense>>(
                  future: _expensesForSelectedDate(_reportDate),
                  builder: (context, snapshot) {
                    if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                      double totalAmount =
                          snapshot.data!.fold(0, (pv, e) => pv + e.amount);
                      return Column(
                        children: [
                          const SizedBox(
                            height: 16.0,
                          ),
                          Text('Total Amount: $totalAmount',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 24)),
                          const SizedBox(
                            height: 8.0,
                          ),
                          Expanded(
                              child: ListView(
                            children: snapshot.data!.map((expense.Expense e) {
                              return expense.ExpenseItem(
                                expense: e,
                                updateExpense: _updateExpense,
                                deleteExpense: _deleteExpense,
                              );
                            }).toList(),
                          )),
                        ],
                      );
                    } else if (snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return const Center(child: Text('No expenses.'));
                    } else if (snapshot.hasError) {
                      return const Text('Error loading expenses.');
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.add), text: 'Add Expense'),
          Tab(icon: Icon(Icons.pie_chart), text: 'Monthly Chart'),
          Tab(icon: Icon(Icons.calendar_today), text: 'Select Date'),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(expense.Expense expense) async {
    final nameEditController = TextEditingController(text: expense.name);
    final amountEditController =
        TextEditingController(text: expense.amount.toString());
    String categoryEditText = expense.category;
    DateTime editDate = DateTime.parse(expense.date);

    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Edit Expense"),
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: nameEditController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an expense name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: amountEditController,
                          decoration:
                              const InputDecoration(labelText: 'Amount'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            double? amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                          value: categoryEditText,
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              categoryEditText = value!;
                            });
                          },
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                        ),
                        const SizedBox(height: 16.0),
                        const Text('Select Date:'),
                        const SizedBox(height: 8.0),
                        Text(
                          '${editDate.year}-${editDate.month}-${editDate.day}',
                          key: ValueKey(editDate),
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 8.0),
                        ElevatedButton(
                          onPressed: () async {
                            showDatePicker(
                              context: context,
                              initialDate: editDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            ).then((selectedDate) {
                              if (selectedDate != null) {
                                setState(() {
                                  editDate = selectedDate;
                                });
                                setState(() {});
                              }
                            });
                          },
                          child: const Text('Choose Date'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      try {
                        if (_formKey.currentState!.validate()) {
                          _saveExpense(
                              expense.id,
                              nameEditController.text,
                              amountEditController.text,
                              categoryEditText,
                              editDate);
                        }
                      } catch (e) {
                        _showExpenseErrorDialog(context);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text("Save")),
              ]);
        });
  }

  Future<List<expense.Expense>> _expensesForSelectedDate(DateTime date) async {
    List<Map<String, dynamic>> queryRows =
        await _dbHelper.getExpensesByDate(date);
    List<expense.Expense> expenses =
        List<expense.Expense>.generate(queryRows.length, (index) {
      return expense.Expense(
        id: queryRows[index]['id'],
        name: queryRows[index]['name'],
        amount: queryRows[index]['amount'],
        category: queryRows[index]['category'],
        date: queryRows[index]['date'],
      );
    });

    return expenses.toList();
  }

  Future<Map<String, double>> _getExpenseCategories() async {
    List<Map<String, dynamic>> queryRows =
        await _dbHelper.getExpensesByThisMonth(_chartDate);
    Map<String, double> expenseMap = {};

    for (var row in queryRows) {
      if (expenseMap.containsKey(row['category'])) {
        expenseMap[row['category']] ??= 0;
        expenseMap[row['category']] =
            expenseMap[row['category']]! + row['amount'].toDouble();
      } else {
        expenseMap[row['category']] = row['amount'];
      }
    }

    return expenseMap;
  }

}
