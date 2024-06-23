import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:dio/dio.dart';

import '../utils.dart';

class OfflineAppointment extends StatefulWidget {
  @override
  _OfflineAppointmentState createState() => _OfflineAppointmentState();
}

Position? _currentpos;
bool locationfetched=false;
class _OfflineAppointmentState extends State<OfflineAppointment> {

  _getCurrentLoc() async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
    setState(() {
      _currentpos=position;
      locationfetched=true;
    });
    _goToUserLoc();
    searchNearby();
  }

  static const String API_KEY = 'AIzaSyBoBDMc51gKPWfRkYy8waqBJdwSB4oGAok';

  Future<List<String>> searchNearby() async {
    double lat = _currentpos!.latitude;
    double lng = _currentpos!.longitude;
    var dio = Dio();
    var url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    var parameters = {
      "key": API_KEY,
      "location": "$lat,$lng",
      "radius": "2000",
      "type": "hospital"
    };

    try {
      final response = await dio.get(url, queryParameters: parameters);

      // TODO: Handle the response here, parse it, and extract the relevant data.
      // The response typically contains a list of nearby places like hospitals.
      print(response);
      // Return the list of nearby hospital names or any other relevant data.

      return [];
    } catch (error) {
      // Handle errors here
      print("Error: $error");
      throw error; // You might want to handle this differently in your app
    }
  }

  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(19.076090,72.877426),
    zoom: 14.4746,
  );

  static final CameraPosition _userlocation = CameraPosition(
      target: LatLng(_currentpos!.latitude,_currentpos!.longitude),
      zoom: 16);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: new Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          flexibleSpace: Container(
            decoration: gradient,
          ),
          title: Text("Google Maps",style: TextStyle(color: Colors.black),),
          centerTitle: true,
          backgroundColor: Color(0xff3EEBB4),
        ),
        body: Column(
          children: [
            Container(
              width:MediaQuery.of(context).size.width,
              height: 350,
              child: GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child:
              Container(
                height: MediaQuery.of(context).size.height*0.07,
                child:OutlinedButton(
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(Color(0xff3EEBB4)),
                    side: MaterialStateProperty.all(BorderSide(color: Color(0xff3EEBB4))),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    ),
                  ),
                  onPressed: _getCurrentLoc,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Get Nearby Medical Facilities"),
                      SizedBox(width: 10),
                      Icon(Icons.location_searching)
                    ],
                  ),
                )
                ,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30,0,30,0),
              child: Divider(
                thickness: 0.3,
                color: Color(0xff3EEBB4),
              ),
            ),
            Container(
              child: Text("List Of Doctors Here"),
            )
          ],
        ),
      ),
    );
  }
  Future<void> _goToUserLoc() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_userlocation));
  }
}
