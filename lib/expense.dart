import 'package:flutter/material.dart';

class Expense {
  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
  });

  final int id;
  final String name;
  final double amount;
  final String category;
  final String date;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'date': date,
    };
  }
}

class ExpenseItem extends StatelessWidget {
  ExpenseItem({
    required this.expense,
    required this.updateExpense,
    required this.deleteExpense,
  }) : super(key: ObjectKey(expense));

  final Expense expense;
  final void Function(Expense expense) updateExpense;
  final void Function(Expense expense) deleteExpense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      title: Row(
        children: <Widget>[
          Expanded(
              child: Text(
            expense.name,
          )),
          Expanded(
              child: Text(
            '${expense.amount}',
          )),
          Expanded(
              child: Text(
            expense.category,
          )),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (String choice) {
          if (choice == 'Edit') {
            updateExpense(expense);
          } else if (choice == 'Delete') {
            deleteExpense(expense);
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            {'text': 'Edit', 'icon': Icons.edit},
            {'text': 'Delete', 'icon': Icons.delete},
          ].map((option) {
            return PopupMenuItem<String>(
              value: option['text'].toString(),
              child: Row(
                children: <Widget>[
                  Icon(option['icon'] as IconData),
                  const SizedBox(width: 8),
                  Text(option['text'].toString()),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
