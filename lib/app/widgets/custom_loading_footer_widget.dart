import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CustomLoadingFooterWidget extends StatelessWidget {
  const CustomLoadingFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFooter(
      builder: (BuildContext context, LoadStatus? mode) {
        Widget body;
        if (mode == LoadStatus.loading) {
          body = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 0.5,
                  color: Colors.grey,
                ),
              ),
              SizedBox(width: 6.0),
              Text(
                'refresh.loading'.tr,
              )
            ],
          );
        } else {
          body = SizedBox();
        }
        return SizedBox(
          height: 30.0,
          child: Center(child: body),
        );
      },
    );
  }
}
