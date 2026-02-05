import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CustomRefreshHeaderWidget extends StatelessWidget {
  const CustomRefreshHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomHeader(
      builder: (BuildContext context, RefreshStatus? mode) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 15,
                width: 15.0,
                child: CircularProgressIndicator(
                  strokeWidth: 0.5,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 6.0),
              Text(
                'refresh.refreshing'.tr,
              ),
            ],
          ),
        );
      },
    );
  }
}
