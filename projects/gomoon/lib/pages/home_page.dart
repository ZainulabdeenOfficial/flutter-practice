import 'package:flutter/material.dart';
import 'package:gomoon/Widgets/custom_Widget_dropdownbutton.dart';

class Home extends StatelessWidget {
  late double _deviceHeight, _devicewidth;

  Home({super.key});

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _devicewidth = MediaQuery.of(context).size.width;

    return Scaffold(
        body: SafeArea(
            child: Container(
      height: _deviceHeight,
      width: _devicewidth,
      padding: EdgeInsets.symmetric(horizontal: _devicewidth * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_pageTitle(), _bookRiderWidget()],
      ),
    )));
  }

  Widget _pageTitle() {
    return const Text(
      "Gomoon",
      style: TextStyle(
          color: Colors.white, fontSize: 70, fontWeight: FontWeight.w800),
    );
  }

  Widget _austroimagewidget() {
    return Container(
       height:  _deviceHeight *  0.50,
       width: _devicewidth * 0.56,
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage("assets/images/astro_moon.png"),
        ),
      ),
    );
  }

  Widget _bookRiderWidget() {
    return  Container(
      height: _deviceHeight * 0.25,
      child: Stack(children:
      [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _dropdownwediget(),
            _travelerinfromationwidget(),
            _ridebutton()
          ],
        ),

        Align(alignment: Alignment.centerRight,child: _austroimagewidget(),)
      ],
      ),
    );
  }

  Widget _dropdownwediget() {
    return CustomDropdownButton(
        values: const ['Zain Web station', 'AbdWidgetStation'],
        width: _devicewidth);
  }

  Widget _travelerinfromationwidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomDropdownButton(values: const [
          '1',
          '2',
          '3',
        ], width: _devicewidth * 0.45),
        CustomDropdownButton(
            values: const ['Economy', 'Business', 'First', 'private'],
            width: _devicewidth * 0.40),
      ],
    );
  }

  Widget _ridebutton() {
    return Container(
      margin: EdgeInsets.only(bottom: _deviceHeight * 0.01),
      width: _devicewidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)
      ),
      child: MaterialButton(
        onPressed: () {},
        child: Text(
          'Book Ride',
          style: TextStyle(color: Colors.black),

        ),
      ),
    );
  }
}
