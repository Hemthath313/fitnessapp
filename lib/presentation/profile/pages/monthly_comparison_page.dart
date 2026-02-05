import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyComparisonPage extends StatefulWidget {
  const MonthlyComparisonPage({super.key});

  @override
  State<MonthlyComparisonPage> createState() => _MonthlyComparisonPageState();
}

class _MonthlyComparisonPageState extends State<MonthlyComparisonPage> {
  // Map<Month, Map<BodyPart, Value>>
  final Map<int, Map<String, double>> _historyData = {};
  bool _isLoading = true;
  int? _selectedMonth1;
  int? _selectedMonth2;

  final List<String> _bodyParts = [
    'chest', 'shoulders', 'biceps', 'foreArm', 'waist', 'hips', 'thigh', 'calf'
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Default current month if data exists
    final currentMonth = DateTime.now().month;
    _selectedMonth1 = currentMonth == 1 ? 12 : currentMonth - 1;
    _selectedMonth2 = currentMonth;

    try {
      for (var part in _bodyParts) {
        final spots = await provider.fetchMeasurementSpots(part);
        for (var spot in spots) {
          final month = spot.x.toInt();
          final value = spot.y;
          
          if (!_historyData.containsKey(month)) {
            _historyData[month] = {};
          }
          _historyData[month]![part] = value;
        }
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        backgroundColor: ColorManager.darkGrey,
        title: Text('Monthly Comparison', style: StyleManager.skillNameTextStyle),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildMonthSelectors(),
                  SizedBox(height: 24.h),
                  _buildComparisonTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelectors() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown('Month 1', _selectedMonth1, (val) {
              setState(() => _selectedMonth1 = val);
            }),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Icon(Icons.compare_arrows, color: ColorManager.primary, size: 28.sp),
          ),
          Expanded(
            child: _buildDropdown('Month 2', _selectedMonth2, (val) {
              setState(() => _selectedMonth2 = val);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, int? value, Function(int?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: ColorManager.background,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: ColorManager.background,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              hint: Text('Select', style: TextStyle(color: Colors.white54)),
              items: List.generate(12, (index) {
                final monthIndex = index + 1;
                return DropdownMenuItem(
                  value: monthIndex,
                  child: Text(DateFormat('MMMM').format(DateTime(2024, monthIndex))),
                );
              }),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    if (_selectedMonth1 == null || _selectedMonth2 == null) {
      return Center(
        child: Text(
          'Please select two months to compare',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final data1 = _historyData[_selectedMonth1] ?? {};
    final data2 = _historyData[_selectedMonth2] ?? {};

    if (data1.isEmpty && data2.isEmpty) {
       return Center(
        child: Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Text(
            'No data available for selected months',
            style: TextStyle(color: Colors.white54),
            ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Divider(color: Colors.white12, height: 1),
          ..._bodyParts.map((part) {
             final val1 = data1[part];
             final val2 = data2[part];
             return _buildTableRow(part, val1, val2);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Body Part', style: _headerStyle)),
          Expanded(child: Text('M1', style: _headerStyle, textAlign: TextAlign.center)),
          Expanded(child: Text('M2', style: _headerStyle, textAlign: TextAlign.center)),
          Expanded(child: Text('Diff', style: _headerStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTableRow(String part, double? val1, double? val2) {
    String diffText = '-';
    Color diffColor = Colors.white54;

    if (val1 != null && val2 != null) {
      double diff = val2 - val1;
      if (diff > 0) {
        diffText = '+${diff.toStringAsFixed(1)}';
        diffColor = Colors.greenAccent;
      } else if (diff < 0) {
        diffText = diff.toStringAsFixed(1);
        diffColor = Colors.redAccent;
      } else {
        diffText = '0.0';
        diffColor = Colors.white54;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _capitalize(part),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              val1 != null ? val1.toStringAsFixed(1) : '-',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              val2 != null ? val2.toStringAsFixed(1) : '-',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              diffText,
              style: TextStyle(color: diffColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: ColorManager.textSecondary,
    fontSize: 12.sp,
    fontWeight: FontWeight.bold,
  );

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
