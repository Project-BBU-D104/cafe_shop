import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/widget/custom_app_bar.dart';
import 'package:intl/intl.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() =>
      _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime startDate = DateTime(2026, 10, 1);
  DateTime endDate = DateTime(2026, 10, 31);

  bool showKpi = true;
  bool showChart = true;
  bool showTable = true;

  String searchText = '';

  final dateFormat = DateFormat('dd MMM yyyy');
  final currencyFormat = NumberFormat('#,##0.00');

  final List<Map<String, dynamic>> sales = [
    {
      'invoice': 'INV-001',
      'customer': 'John',
      'date': DateTime(2026, 10, 2),
      'total': 150.00,
      'status': 'Paid',
    },
    {
      'invoice': 'INV-002',
      'customer': 'David',
      'date': DateTime(2026, 10, 5),
      'total': 230.00,
      'status': 'Paid',
    },
    {
      'invoice': 'INV-003',
      'customer': 'Sokha',
      'date': DateTime(2026, 10, 8),
      'total': 95.50,
      'status': 'Pending',
    },
    {
      'invoice': 'INV-004',
      'customer': 'Dara',
      'date': DateTime(2026, 10, 12),
      'total': 320.00,
      'status': 'Paid',
    },
    {
      'invoice': 'INV-005',
      'customer': 'Lina',
      'date': DateTime(2026, 10, 15),
      'total': 180.00,
      'status': 'Paid',
    },
    {
      'invoice': 'INV-006',
      'customer': 'Vanna',
      'date': DateTime(2026, 10, 20),
      'total': 275.00,
      'status': 'Pending',
    },
  ];

  List<Map<String, dynamic>> get filteredSales {
    return sales.where((sale) {
      final DateTime date = sale['date'];

      final bool inDateRange =
          !date.isBefore(DateUtils.dateOnly(startDate)) &&
          !date.isAfter(DateUtils.dateOnly(endDate));

      final String invoice =
          sale['invoice'].toString().toLowerCase();
      final String customer =
          sale['customer'].toString().toLowerCase();
      final String query = searchText.toLowerCase();

      final bool matchesSearch =
          invoice.contains(query) ||
          customer.contains(query);

      return inDateRange && matchesSearch;
    }).toList();
  }

  double get totalSales {
    return filteredSales.fold<double>(
      0,
      (sum, sale) => sum + (sale['total'] as num).toDouble(),
    );
  }

  int get totalOrders => filteredSales.length;

  double get averageOrderValue {
    if (totalOrders == 0) return 0;
    return totalSales / totalOrders;
  }

  Future<void> chooseDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;

        if (startDate.isAfter(endDate)) {
          endDate = startDate;
        }
      } else {
        endDate = picked;

        if (endDate.isBefore(startDate)) {
          startDate = endDate;
        }
      }
    });
  }

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget dateButton({
    required String label,
    required DateTime date,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        '$label: ${dateFormat.format(date)}',
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget buildDateFilter() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Date Range Filter',
              Icons.date_range,
            ),
            const SizedBox(height: 16),

            // Keep both date filters in the same section.
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide =
                    constraints.maxWidth >= 450;

                final fromButton = dateButton(
                  label: 'From',
                  date: startDate,
                  icon: Icons.calendar_today,
                  onPressed: () => chooseDate(true),
                );

                final toButton = dateButton(
                  label: 'To',
                  date: endDate,
                  icon: Icons.event,
                  onPressed: () => chooseDate(false),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: fromButton),
                      const SizedBox(width: 12),
                      Expanded(child: toButton),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    fromButton,
                    const SizedBox(height: 8),
                    toButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildKpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildKpiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Sales Overview', Icons.dashboard),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final int columns =
                constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 500
                        ? 3
                        : 1;

            final double itemWidth =
                (constraints.maxWidth -
                    (columns - 1) * 12) /
                columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: buildKpiCard(
                    title: 'Total Sales',
                    value:
                        '\$${currencyFormat.format(totalSales)}',
                    
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: buildKpiCard(
                    title: 'Total Orders',
                    value: '$totalOrders',
                   
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: buildKpiCard(
                    title: 'Average Order',
                    value:
                        '\$${currencyFormat.format(averageOrderValue)}',
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget buildChartSection() {
    // Sales total for each day in the selected date range.
    final List<FlSpot> spots = [];

    for (int i = 0; i < 7; i++) {
      final DateTime day =
          startDate.add(Duration(days: i));

      final double dayTotal = filteredSales
          .where((sale) =>
              DateUtils.isSameDay(sale['date'], day))
          .fold<double>(
            0,
            (sum, sale) =>
                sum + (sale['total'] as num).toDouble(),
          );

      spots.add(FlSpot(i.toDouble(), dayTotal));
    }

    final double maxY = spots.fold<double>(
      0,
      (maximum, spot) =>
          spot.y > maximum ? spot.y : maximum,
    );

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Sales Chart',
              Icons.show_chart,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY == 0 ? 100 : maxY * 1.2,
                  gridData: const FlGridData(
                    show: true,
                  ),
                  borderData: FlBorderData(
                    show: true,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();

                          if (index < 0 || index >= 7) {
                            return const SizedBox.shrink();
                          }

                          final DateTime day =
                              startDate.add(
                            Duration(days: index),
                          );

                          return Padding(
                            padding:
                                const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(day),
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.blue,
                      dotData: const FlDotData(
                        show: true,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTableSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Sales Details',
              Icons.receipt_long,
            ),
             

           
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Invoice')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Date')),
                    DataColumn(
                      label: Text('Total'),
                      numeric: true,
                    ),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: filteredSales.map((sale) {
                    final bool isPaid =
                        sale['status'] == 'Paid';

                    return DataRow(
                      cells: [
                        DataCell(Text(sale['invoice'])),
                        DataCell(Text(sale['customer'])),
                        DataCell(
                          Text(dateFormat.format(
                            sale['date'],
                          )),
                        ),
                        DataCell(
                          Text(
                            '\$${currencyFormat.format(sale['total'])}',
                          ),
                        ),
                        DataCell(
                          Text(
                            sale['status'],
                            style: TextStyle(
                              color: isPaid
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget visibilityCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget buildCustomizeReport() {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: const Text(
          'Customize Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16),
        children: [
          visibilityCheckbox(
            title: 'Show KPI Cards',
            value: showKpi,
            onChanged: (value) {
              setState(() => showKpi = value ?? true);
            },
          ),
          visibilityCheckbox(
            title: 'Show Sales Chart',
            value: showChart,
            onChanged: (value) {
              setState(() => showChart = value ?? true);
            },
          ),
          visibilityCheckbox(
            title: 'Show Sales Table',
            value: showTable,
            onChanged: (value) {
              setState(() => showTable = value ?? true);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Sales Report" ,
        centerTitle: false,
        showRefresh: true,
        onRefresh: () => setState(() {
          
        }),
        actions: [
          IconButton(
            tooltip: 'Reset filters',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                startDate = DateTime(2026, 10, 1);
                endDate = DateTime(2026, 10, 31);
                searchText = '';
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth =
                constraints.maxWidth > 1200
                    ? 1200
                    : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // The two date filters stay grouped.
                    buildDateFilter(),

                    const SizedBox(height: 16),

                    buildCustomizeReport(),

                    if (showKpi) ...[
                      const SizedBox(height: 16),
                      buildKpiSection(),
                    ],

                    if (showChart) ...[
                      const SizedBox(height: 16),
                      buildChartSection(),
                    ],

                    if (showTable) ...[
                      const SizedBox(height: 16),
                      buildTableSection(),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}