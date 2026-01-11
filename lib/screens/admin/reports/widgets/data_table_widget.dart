import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../../../../../theme/cyberpunk_theme.dart';

class DataTableWidget {
  static TextStyle _tableHeaderStyle() {
    return GoogleFonts.rajdhani(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: CyberpunkTheme.textPrimary,
      letterSpacing: 1,
    );
  }

  static TextStyle _tableCellStyle() {
    return GoogleFonts.rajdhani(
      fontSize: 12,
      color: CyberpunkTheme.textPrimary,
    );
  }

  static Widget buildUserTable(List<Map<String, dynamic>> users) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 600),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        smRatio: 0.75,
        lmRatio: 1.5,
        columns: [
          DataColumn2(
            label: Text('ID', style: _tableHeaderStyle()),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text('NAME', style: _tableHeaderStyle()),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('EMAIL', style: _tableHeaderStyle()),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('ROLE', style: _tableHeaderStyle()),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text('STATUS', style: _tableHeaderStyle()),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text('JOINED', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
        ],
        rows: users.map((user) {
          return DataRow2(
            cells: [
              DataCell(
                Text(
                  (user['id'] as String).substring(0, 8),
                  style: _tableCellStyle(),
                ),
              ),
              DataCell(Text(user['name'].toString(), style: _tableCellStyle())),
              DataCell(
                Text(user['email'].toString(), style: _tableCellStyle()),
              ),
              DataCell(_buildRoleChip(user['role'].toString())),
              DataCell(_buildStatusChip(user['status'] as String?)),
              DataCell(
                Text(
                  user['createdAt'] != null
                      ? DateFormat(
                          'dd/MM/yy',
                        ).format(user['createdAt'] as DateTime)
                      : 'N/A',
                  style: _tableCellStyle(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget buildAssetTable(List<Map<String, dynamic>> assets) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 600),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        smRatio: 0.75,
        lmRatio: 1.5,
        columns: [
          DataColumn2(
            label: Text('ASSET', style: _tableHeaderStyle()),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('CATEGORY', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text('STATUS', style: _tableHeaderStyle()),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text('VALUE', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text('LOCATION', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text('ADDED', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
        ],
        rows: assets.map((asset) {
          return DataRow2(
            cells: [
              DataCell(
                Text(asset['name'].toString(), style: _tableCellStyle()),
              ),
              DataCell(
                Text(asset['category'].toString(), style: _tableCellStyle()),
              ),
              DataCell(_buildAssetStatusChip(asset['status'].toString())),
              DataCell(
                Text(
                  '\$${(asset['value'] as double?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: _tableCellStyle(),
                ),
              ),
              DataCell(
                Text(asset['location'].toString(), style: _tableCellStyle()),
              ),
              DataCell(
                Text(
                  asset['createdAt'] != null
                      ? DateFormat(
                          'dd/MM/yy',
                        ).format(asset['createdAt'] as DateTime)
                      : 'N/A',
                  style: _tableCellStyle(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget buildBorrowingTable(List<Map<String, dynamic>> borrowings) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 600),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        smRatio: 0.75,
        lmRatio: 1.5,
        columns: [
          DataColumn2(
            label: Text('ASSET', style: _tableHeaderStyle()),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('USER', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text('STATUS', style: _tableHeaderStyle()),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text('REQUESTED', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text('APPROVED', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Text('RETURNED', style: _tableHeaderStyle()),
            size: ColumnSize.M,
          ),
        ],
        rows: borrowings.map((borrowing) {
          return DataRow2(
            cells: [
              DataCell(
                Text(
                  borrowing['assetName'].toString(),
                  style: _tableCellStyle(),
                ),
              ),
              DataCell(
                Text(
                  borrowing['userName'].toString(),
                  style: _tableCellStyle(),
                ),
              ),
              DataCell(
                _buildBorrowingStatusChip(borrowing['status'].toString()),
              ),
              DataCell(
                Text(
                  borrowing['requestedDate'] != null
                      ? DateFormat(
                          'dd/MM/yy',
                        ).format(borrowing['requestedDate'] as DateTime)
                      : 'N/A',
                  style: _tableCellStyle(),
                ),
              ),
              DataCell(
                Text(
                  borrowing['approvedDate'] != null
                      ? DateFormat(
                          'dd/MM/yy',
                        ).format(borrowing['approvedDate'] as DateTime)
                      : 'N/A',
                  style: _tableCellStyle(),
                ),
              ),
              DataCell(
                Text(
                  borrowing['returnedDate'] != null
                      ? DateFormat(
                          'dd/MM/yy',
                        ).format(borrowing['returnedDate'] as DateTime)
                      : 'N/A',
                  style: _tableCellStyle(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildRoleChip(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.rajdhani(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static Widget _buildStatusChip(String? status) {
    final isActive = status == 'active';
    final color = isActive ? CyberpunkTheme.neonGreen : Colors.red;
    final text = status?.toUpperCase() ?? 'UNKNOWN';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.rajdhani(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static Widget _buildAssetStatusChip(String status) {
    final color = _getAssetStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.rajdhani(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static Widget _buildBorrowingStatusChip(String status) {
    final color = _getBorrowingStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.rajdhani(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return CyberpunkTheme.primaryPink;
      case 'staff':
        return CyberpunkTheme.primaryCyan;
      case 'student':
        return CyberpunkTheme.neonGreen;
      default:
        return CyberpunkTheme.primaryPurple;
    }
  }

  static Color _getAssetStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return CyberpunkTheme.neonGreen;
      case 'in use':
      case 'on loan':
        return CyberpunkTheme.primaryPink;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.grey;
      default:
        return CyberpunkTheme.primaryCyan;
    }
  }

  static Color _getBorrowingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return CyberpunkTheme.neonGreen;
      case 'returned':
        return CyberpunkTheme.primaryCyan;
      case 'rejected':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      default:
        return CyberpunkTheme.primaryPurple;
    }
  }
}
