import 'package:flutter/material.dart';
import 'package:frontend/constants/constant.dart';
import 'package:frontend/controllers/profile_controller.dart';
import 'package:get/get.dart';

class CardProfileWidget extends StatelessWidget {

  CardProfileWidget({super.key});
    final ctr = Get.find<ProfileController>(); 

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(  
        margin: const EdgeInsets.only(bottom: 10),
        color: titleColor,
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: ctr.photo.value.isNotEmpty &&
                          ctr.photo.value.isNotEmpty
                      ? NetworkImage(ctr.photo.value)
                      : const NetworkImage('https://imgs.search.brave.com/Y20_Qf09jZ8KyraFayP-Bh7mXPopmU4Pc6JBLcB4CBY/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMjcv/OTUxLzEzMC9zbWFs/bC9hZnJpY2EtZ3V5/LTNkLWF2YXRhci1j/aGFyYWN0ZXItaWxs/dXN0cmF0aW9ucy1w/bmcucG5n'),
                ),
                const SizedBox(height: 5,),
                Obx(()=> Text(
                    ctr.username.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,   
                    ),
                  ),
                ),
                // Text(ctr.role.value, style: TextStyle(
                //     fontWeight: FontWeight.w500,
                //     fontSize: 20,   
                //   ),),

                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.shade100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ctr.role.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ),
    );
  }
}