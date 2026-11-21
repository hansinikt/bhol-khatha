import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

part 'database.g.dart';

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get preferredLang => text().withDefault(const Constant('hi'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get type => text()(); // 'credit' | 'payment'
  IntColumn get amountRupees => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

class VoiceQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get audioPath => text()();
  TextColumn get lang => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Customers, Transactions, VoiceQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String encryptionKey) : super(_open(encryptionKey));

  @override
  int get schemaVersion => 1;

  Future<int> addCustomer(String name, {String? phone, String lang = 'hi'}) =>
      into(customers).insert(CustomersCompanion.insert(
          name: name, phone: Value(phone), preferredLang: Value(lang)));

  Future<int> addTransaction(int customerId, String type, int amount,
          {String? note}) =>
      into(transactions).insert(TransactionsCompanion.insert(
          customerId: customerId,
          type: type,
          amountRupees: amount,
          note: Value(note)));

  Future<List<Transaction>> historyFor(int customerId) =>
      (select(transactions)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<Customer?> findByName(String name) => (select(customers)
        ..where((c) => c.name.lower().equals(name.toLowerCase())))
      .getSingleOrNull();
}

LazyDatabase _open(String key) => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'bolkhata.db'));
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      return NativeDatabase.createInBackground(file, setup: (db) {
        db.execute("PRAGMA key = '$key';");
      });
    });