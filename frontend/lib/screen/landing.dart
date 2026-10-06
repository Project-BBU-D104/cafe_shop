import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: infoColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FA), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    "assets/icon/logo.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // InventoryPro នៅកណ្ដាល
              const Center(
                child: Text(
                  "គ្រប់គ្រងស្តុកទីទីម៉ាត",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Synchronizing warehouse data... នៅក្រោម
              const Center(
                child: Text(
                  "កំពុងដំណើរការទិន្នន័យស្តុកទីទីម៉ាត",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
