import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/widgets/app_image.dart';

class VerticalPlaceItem extends StatelessWidget {
  const VerticalPlaceItem({super.key, required this.place});

  final Map<String, dynamic> place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
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
          height: 70.0,
          child: Row(
            children: <Widget>[
              AppImage(
                src: '${place["img"]}',
                height: 70.0,
                width: 70.0,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 15.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${place["name"]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(Icons.location_on,
                            size: 13.0, color: Colors.blueGrey[300]),
                        const SizedBox(width: 3.0),
                        Expanded(
                          child: Text(
                            '${place["location"]}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.blueGrey[400],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place["price"]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
