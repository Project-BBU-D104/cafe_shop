import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';

class LandingScreen
    extends
        StatelessWidget {
  const LandingScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: infoColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(
                  0xFFFFF9F7,
                ),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ================= LOGO =================
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    25,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    25,
                  ),
                  child: Image.asset(
                    "assets/icon/icon.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ================= APP NAME =================
              const Text(
                "Roast & Brew",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(
                    0xFF35180C,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ================= SUBTITLE =================
              const Text(
                "ប្រព័ន្ធគ្រប់គ្រងការលក់កាហ្វេ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(
                    0xFF5D4037,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ================= DESCRIPTION =================
              const Text(
                "Coffee Sales Management System",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ================= LOADING =================
              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(
                    0xFF35180C,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                "កំពុងរៀបចំប្រព័ន្ធលក់កាហ្វេ...",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
