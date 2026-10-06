import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:frontend/controllers/profile_controller.dart';
import 'package:get/get.dart';

class CardPersonalInfoWidget extends StatelessWidget {
  CardPersonalInfoWidget({super.key});

  final ctr = Get.find<ProfileController>(); 
  

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: titleColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_outlined),
                  SizedBox(width: 10,),
                  Text("Personal Info Widget".tr, style: TextStyle(fontWeight: FontWeight.bold),),
                ],
              ),
              Divider(),
              
              Text("Full Name".tr, style: TextStyle(fontWeight: FontWeight.w600),),
              SizedBox(height: 5,),
              Obx(() => cardInfo(
                  title: ctr.username.value,
                ),
              ),
              SizedBox(height: 10,),

              Text("Email Address".tr, style: TextStyle(fontWeight: FontWeight.w600),),
              SizedBox(height: 5,),
              Obx(()=> cardInfo(
                  title: ctr.email.value,
                ),
              ),
              
              if(ctr.phone.value.isNotEmpty) ...[
                SizedBox(height: 10,),
                Text("Phone Number".tr, style: TextStyle(fontWeight: FontWeight.w600),),
                SizedBox(height: 5,),
                cardInfo(
                  title: ctr.phone.value,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

Widget cardInfo({
  required String title,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey.shade300,
      ),
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}