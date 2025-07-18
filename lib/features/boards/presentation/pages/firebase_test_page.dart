import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  String _status = 'Verificando conexión...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      setState(() {
        _status = 'Verificando Firebase...';
      });

      // Verificar que Firebase esté inicializado
      final app = Firebase.app();
      debugPrint('Firebase app: ${app.name}');

      setState(() {
        _status = 'Firebase inicializado. Probando Firestore...';
      });

      // Verificar que Firestore esté disponible
      final firestore = FirebaseFirestore.instance;
      debugPrint('Firestore instance: $firestore');

      setState(() {
        _status = 'Intentando consulta simple...';
      });

      // Intentar una consulta simple
      await firestore.collection('test').limit(1).get();

      setState(() {
        _status = '¡Conexión exitosa! Firestore está funcionando.';
        _isConnected = true;
      });

      debugPrint('Firestore connection successful');
    } catch (e) {
      debugPrint('Firebase connection error: $e');
      setState(() {
        _status = 'Error de conexión: $e';
        _isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Firebase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testFirebaseConnection,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.check_circle : Icons.error_outline,
                size: 80,
                color: _isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                _isConnected ? 'Conectado' : 'Error de Conexión',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (!_isConnected) ...[
                const Text(
                  'Posibles soluciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Ve a Firebase Console\n'
                  '2. Selecciona tu proyecto\n'
                  '3. Ve a "Firestore Database"\n'
                  '4. Haz clic en "Create database"\n'
                  '5. Selecciona "Start in test mode"',
                  textAlign: TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
