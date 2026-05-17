import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/widgets/app_image.dart';

class HorizontalPlaceItem extends StatelessWidget {
  const HorizontalPlaceItem({super.key, required this.place});

  final Map<String, dynamic> place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  Details(place: Map<String, dynamic>.from(place)),
            ),
          );
        },
        child: SizedBox(
          height: 250.0,
          width: 140.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppImage(
                src: '${place["img"]}',
                height: 168.0,
                width: 140.0,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 7.0),
              Text(
                '${place["name"]}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3.0),
              Text(
                '${place["location"]}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                  color: Colors.blueGrey[300],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
