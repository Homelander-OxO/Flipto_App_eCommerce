library order_tracker;

import 'package:flutter/material.dart';

class OrderTracker extends StatefulWidget {
  ///This variable is used to set status of order, this get only enum which is already in a package below example present.
  /// Status.order
  final Status? status;

  /// This variable is used to get list of order sub title and date to show present status of product.
  final List<TextDto>? orderTitleAndDateList;

  final List<TextDto>? packedTitleAndDateList;

  /// This variable is used to get list of shipped sub title and date to show present status of product.
  final List<TextDto>? shippedTitleAndDateList;

  /// This variable is used to get list of outOfDelivery sub title and date to show present status of product.
  final List<TextDto>? outOfDeliveryTitleAndDateList;

  /// This variable is used to get list of delivered sub title and date to show present status of product.
  final List<TextDto>? deliveredTitleAndDateList;

  /// This variable is used to change color of active animation border.
  final Color? activeColor;

  /// This variable is used to change color of inactive animation border.
  final Color? inActiveColor;

  /// This variable is used to change style of heading title text.
  final TextStyle? headingTitleStyle;

  /// This variable is used to change style of heading date text.
  final TextStyle? headingDateTextStyle;

  /// This variable is used to change style of sub title text.
  final TextStyle? subTitleTextStyle;

  /// This variable is used to change style of sub date text.
  final TextStyle? subDateTextStyle;

  // New parameters for heading dates
  final String? orderPlacedDate;
  final String? packagedDate;
  final String? shippedDate;
  final String? outForDeliveryDate;
  final String? deliveredDate;

  const OrderTracker({
    Key? key,
    required this.status,
    this.orderTitleAndDateList,
    this.packedTitleAndDateList,
    this.shippedTitleAndDateList,
    this.outOfDeliveryTitleAndDateList,
    this.deliveredTitleAndDateList,
    this.activeColor,
    this.inActiveColor,
    this.headingTitleStyle,
    this.headingDateTextStyle,
    this.subTitleTextStyle,
    this.subDateTextStyle,
    // New optional parameters
    this.orderPlacedDate,
    this.packagedDate,
    this.shippedDate,
    this.outForDeliveryDate,
    this.deliveredDate,
  }) : super(key: key);

  @override
  State<OrderTracker> createState() => _OrderTrackerState();
}

class _OrderTrackerState extends State<OrderTracker>
    with TickerProviderStateMixin {
  AnimationController? controller;
  AnimationController? controller2;
  AnimationController? controller3;
  AnimationController? controller4;

  bool isFirst = false;
  bool isSecond = false;
  bool isThird = false;
  bool isFourth = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.status?.name == Status.order.name) {
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller?.value != null && controller!.value > 0.99) {
            controller?.stop();
          }
          setState(() {});
        });
    } else if (widget.status?.name == Status.packed.name) {
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller?.value != null && controller!.value > 0.99) {
            controller?.stop();
            isFirst = true;
            controller2?.forward(from: 0.0);
          }
          setState(() {});
        });

      controller2 = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller2?.value != null && controller2!.value > 0.99) {
            controller2?.stop();
            isSecond = true;
            controller3?.forward(from: 0.0);
          }
          setState(() {});
        });
    } else if (widget.status?.name == Status.shipped.name) {
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller?.value != null && controller!.value > 0.99) {
            controller?.stop();
            isFirst = true;
            controller2?.forward(from: 0.0);
          }
          setState(() {});
        });

      controller2 = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller2?.value != null && controller2!.value > 0.99) {
            controller2?.stop();
            isSecond = true;
            controller3?.forward(from: 0.0);
          }
          setState(() {});
        });

      controller3 = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller3?.value != null && controller3!.value > 0.99) {
            controller3?.stop();
            isThird = true;
            controller4?.forward(from: 0.0);
          }
          setState(() {});
        });
    } else if (widget.status?.name == Status.outOfDelivery.name ||
        widget.status?.name == Status.delivered.name) {
      controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller?.value != null && controller!.value > 0.99) {
            controller?.stop();
            isFirst = true;
            controller2?.forward(from: 0.0);
          }
          setState(() {});
        });

      controller2 = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller2?.value != null && controller2!.value > 0.99) {
            controller2?.stop();
            isSecond = true;
            controller3?.forward(from: 0.0);
          }
          setState(() {});
        });

      controller3 = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller3?.value != null && controller3!.value > 0.99) {
            controller3?.stop();
            isThird = true;
            controller4?.forward(from: 0.0);
          }
          setState(() {});
        });

      controller4 = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..addListener(() {
          if (controller4?.value != null && controller4!.value > 0.99) {
            controller4?.stop();
            isFourth = true;
          }
          setState(() {});
        });
    }

    controller?.forward();
  }

  @override
  void dispose() {
    controller?.dispose();
    controller2?.dispose();
    controller3?.dispose();
    controller4?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                      color: widget.activeColor ?? Colors.green,
                      borderRadius: BorderRadius.circular(50)),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "Order Placed  ",
                          style: widget.headingTitleStyle ??
                              const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1)),
                      TextSpan(
                        text: widget.orderPlacedDate ?? "Order being processed",
                        style: widget.headingDateTextStyle ??
                            const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                                letterSpacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 2,
                    height: widget.orderTitleAndDateList != null &&
                            widget.orderTitleAndDateList!.isNotEmpty
                        ? widget.orderTitleAndDateList!.length * 52
                        : 60,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: LinearProgressIndicator(
                        value: controller?.value ?? 0.0,
                        backgroundColor:
                            widget.inActiveColor ?? Colors.grey[300],
                        color: widget.activeColor ?? Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                Expanded(
                  child: ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.orderTitleAndDateList?[index].title ?? "",
                              style: widget.subTitleTextStyle ??
                                  const TextStyle(fontSize: 14),
                            ),
                            Text(
                              widget.orderTitleAndDateList?[index].date ?? "",
                              style: widget.subDateTextStyle ??
                                  TextStyle(
                                      fontSize: 14, color: Colors.grey[400]),
                            )
                          ],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          height: 4,
                        );
                      },
                      itemCount: widget.orderTitleAndDateList != null &&
                              widget.orderTitleAndDateList!.isNotEmpty
                          ? widget.orderTitleAndDateList!.length
                          : 0),
                )
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                      color: (widget.status?.name == Status.packed.name ||
                                  widget.status?.name == Status.shipped.name ||
                                  widget.status?.name ==
                                      Status.outOfDelivery.name ||
                                  widget.status?.name ==
                                      Status.delivered.name) &&
                              isFirst == true
                          ? widget.activeColor ?? Colors.green
                          : widget.inActiveColor ?? Colors.grey[300],
                      borderRadius: BorderRadius.circular(50)),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "Packed  ",
                          style: widget.headingTitleStyle ??
                              const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1)),
                      TextSpan(
                        text: widget.packagedDate ?? "Order being processed",
                        style: widget.headingDateTextStyle ??
                            const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                                letterSpacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 2,
                    height: widget.packedTitleAndDateList != null &&
                            widget.packedTitleAndDateList!.isNotEmpty
                        ? widget.packedTitleAndDateList!.length * 52
                        : 60,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: LinearProgressIndicator(
                        value: controller2?.value ?? 0.0,
                        backgroundColor:
                            widget.inActiveColor ?? Colors.grey[300],
                        color: isFirst == true
                            ? widget.activeColor ?? Colors.green
                            : widget.inActiveColor ?? Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                Expanded(
                  child: ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.packedTitleAndDateList?[index].title ?? "",
                              style: widget.subTitleTextStyle ??
                                  const TextStyle(fontSize: 14),
                            ),
                            Text(
                              widget.packedTitleAndDateList?[index].date ?? "",
                              style: widget.subDateTextStyle ??
                                  TextStyle(
                                      fontSize: 14, color: Colors.grey[400]),
                            )
                          ],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          height: 2,
                        );
                      },
                      itemCount: widget.packedTitleAndDateList != null &&
                              widget.packedTitleAndDateList!.isNotEmpty
                          ? widget.packedTitleAndDateList!.length
                          : 0),
                )
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: (widget.status?.name == Status.shipped.name ||
                                widget.status?.name ==
                                    Status.outOfDelivery.name ||
                                widget.status?.name == Status.delivered.name) &&
                            isSecond == true
                        ? widget.activeColor ?? Colors.green
                        : widget.inActiveColor ?? Colors.grey[300],
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "Shipped  ",
                          style: widget.headingTitleStyle ??
                              const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1)),
                      TextSpan(
                        text: widget.shippedDate ?? "Order being processed",
                        style: widget.headingDateTextStyle ??
                            const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                                letterSpacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 2,
                    height: widget.shippedTitleAndDateList != null &&
                            widget.shippedTitleAndDateList!.isNotEmpty
                        ? widget.shippedTitleAndDateList!.length *
                            31 // Adjust height
                        : 60,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: LinearProgressIndicator(
                        value: controller3?.value ?? 0.0,
                        backgroundColor:
                            widget.inActiveColor ?? Colors.grey[300],
                        color: isSecond == true
                            ? widget.activeColor ?? Colors.green
                            : widget.inActiveColor ?? Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                Expanded(
                  child: ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    // Remove extra padding
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shippedTitleAndDateList?[index].title ?? "",
                            style: widget.subTitleTextStyle ??
                                const TextStyle(fontSize: 14),
                          ),
                          if (widget.shippedTitleAndDateList?[index].date
                                  ?.isNotEmpty ??
                              false)
                            const SizedBox(height: 0), // Reduce spacing
                          if (widget.shippedTitleAndDateList?[index].date
                                  ?.isNotEmpty ??
                              false)
                            Text(
                              widget.shippedTitleAndDateList?[index].date ?? "",
                              style: widget.subDateTextStyle ??
                                  TextStyle(
                                      fontSize: 14, color: Colors.grey[400]),
                            ),
                          if (widget.shippedTitleAndDateList?[index].cities
                                  ?.isNotEmpty ??
                              false)
                            const SizedBox(height: 0), // Reduce spacing
                          if (widget.shippedTitleAndDateList?[index].cities
                                  ?.isNotEmpty ??
                              false)
                            Text(
                              widget.shippedTitleAndDateList?[index].cities ??
                                  "",
                            ),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                          height: 3); // No spacing between items
                    },
                    itemCount: widget.shippedTitleAndDateList != null &&
                            widget.shippedTitleAndDateList!.isNotEmpty
                        ? widget.shippedTitleAndDateList!.length
                        : 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                      color:
                          (widget.status?.name == Status.outOfDelivery.name ||
                                      widget.status?.name ==
                                          Status.delivered.name) &&
                                  isThird == true
                              ? widget.activeColor ?? Colors.green
                              : widget.inActiveColor ?? Colors.grey[300],
                      borderRadius: BorderRadius.circular(50)),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "Out of delivery  ",
                          style: widget.headingTitleStyle ??
                              const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1)),
                      TextSpan(
                        text: widget.outForDeliveryDate ??
                            "Order being processed",
                        style: widget.headingDateTextStyle ??
                            const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                                letterSpacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 2,
                    height: widget.outOfDeliveryTitleAndDateList != null &&
                            widget.outOfDeliveryTitleAndDateList!.isNotEmpty
                        ? widget.outOfDeliveryTitleAndDateList!.length * 56
                        : 60,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: LinearProgressIndicator(
                        value: controller4?.value ?? 0.0,
                        backgroundColor:
                            widget.inActiveColor ?? Colors.grey[300],
                        color: isThird == true
                            ? widget.activeColor ?? Colors.green
                            : widget.inActiveColor ?? Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                Expanded(
                  child: ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.outOfDeliveryTitleAndDateList?[index]
                                      .title ??
                                  "",
                              style: widget.subTitleTextStyle ??
                                  const TextStyle(fontSize: 14),
                            ),
                            Text(
                              widget.outOfDeliveryTitleAndDateList?[index]
                                      .date ??
                                  "",
                              style: widget.subDateTextStyle ??
                                  TextStyle(
                                      fontSize: 14, color: Colors.grey[400]),
                            )
                          ],
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          height: 4,
                        );
                      },
                      itemCount: widget.outOfDeliveryTitleAndDateList != null &&
                              widget.outOfDeliveryTitleAndDateList!.isNotEmpty
                          ? widget.outOfDeliveryTitleAndDateList!.length
                          : 0),
                )
              ],
            ),
          ],
        ),
        Column(
          children: [
            Row(
              children: [
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                      color: widget.status?.name == Status.delivered.name &&
                              isFourth == true
                          ? widget.activeColor ?? Colors.green
                          : widget.inActiveColor ?? Colors.grey[300],
                      borderRadius: BorderRadius.circular(50)),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "Delivered  ",
                          style: widget.headingTitleStyle ??
                              const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1)),
                      TextSpan(
                        text: widget.deliveredDate ?? "Order being processed",
                        style: widget.headingDateTextStyle ??
                            const TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                                letterSpacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.only(left: 40, top: 6),
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.deliveredTitleAndDateList?[index].title ?? "",
                        style: widget.subTitleTextStyle ??
                            const TextStyle(fontSize: 14),
                      ),
                      Text(
                        widget.deliveredTitleAndDateList?[index].date ?? "",
                        style: widget.subDateTextStyle ??
                            TextStyle(fontSize: 14, color: Colors.grey[400]),
                      )
                    ],
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    height: 4,
                  );
                },
                itemCount: widget.deliveredTitleAndDateList != null &&
                        widget.deliveredTitleAndDateList!.isNotEmpty
                    ? widget.deliveredTitleAndDateList!.length
                    : 0)
          ],
        ),
      ],
    );
  }
}

class TextDto {
  String? title;
  String? date;
  String? cities;

  TextDto(this.title, this.date, this.cities);
}

enum Status { order, packed, shipped, outOfDelivery, delivered }
