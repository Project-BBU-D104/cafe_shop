import 'package:flutter/material.dart';
import 'package:frontend/screen/home/widget/quick_action_widget.dart';
// import 'package:frontend/screen/home/widget/recent_purchase_order_widget.dart';
// import 'package:frontend/screen/home/widget/recent_sale_widget.dart';
import 'package:frontend/screen/home/widget/welcome_widget.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                SizedBox(
                  width: double.infinity,
                  child: WelcomeWidget()
                ),

                SizedBox(height: 15,),

                QuickActionWidget(),

                SizedBox(height: 15,),

                // RecentStockInWidget(),

                // RecentStockOutWidget(),
              ]
            ),
          )
        )
      )
    );
  }
}