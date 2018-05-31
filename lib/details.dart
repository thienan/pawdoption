import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'colors.dart';
import 'animals.dart';

/// Shows detailed profile for the animal.
class DetailsPage extends StatefulWidget {
  DetailsPage({Key key, this.pet}) : super(key: key);

  final Animal pet;

  @override
  _DetailsPage createState() => _DetailsPage();
}

class _DetailsPage extends State<DetailsPage> {
  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: key,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.pet.name,
            style: const TextStyle(fontFamily: 'Raleway')),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            height: 300.0,
            decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                fit: BoxFit.fitHeight,
                image: NetworkImage(widget.pet.imgUrl),
              ),
            ),
          ),
          // TOOD: Try not using a column here. Seems usless.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDogInfo(widget.pet),
              Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text("Comments about ${widget.pet.name}:",
                    style:
                        const TextStyle(fontFamily: 'Raleway', fontSize: 20.0)),
              ),
              _buildComments(key),
            ],
          ),
          Divider(),
          _buildAdoptInfo(),
          widget.pet.id == null || widget.pet.id == 'null'
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Tell them you want to adopt ${widget.pet.name}"
                        " whose ID is ${widget.pet.id}.",
                    textAlign: TextAlign.center,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildComments(GlobalKey<ScaffoldState> key) {
    return FutureBuilder(
      future: getDetailsAbout(widget.pet),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Text('Wait..');
          case ConnectionState.waiting:
            return Text('Loading...');
          default:
            if (snapshot.hasError)
              return new Text(
                  'Couldn\'t get the comments :( ${snapshot.error}');
            else
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: RichText(
                      text: TextSpan(
                        text: snapshot.data[0],
                        style: const TextStyle(
                            fontFamily: 'OpenSans', color: kPetPrimaryText),
                      ),
                    ),
                  ),
                  _buildLinkSection(snapshot.data.sublist(1), key),
                ],
              );
        }
      },
    );
  }

  Widget _createInfoRow(String title, String item) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Text(
            title,
            style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 20.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
            child: Text(item,
                style: const TextStyle(fontFamily: 'Raleway', fontSize: 20.0))),
      ],
    );
  }

  Widget _buildDogInfo(Animal dog) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _createInfoRow("Breed:", widget.pet.breed),
            _createInfoRow("Gender:", widget.pet.gender),
            _createInfoRow("Age:", widget.pet.age),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTags(List<String> urls, GlobalKey<ScaffoldState> key) {
    return Container(
      height: 50.0,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: urls.map((String url) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () async {
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: url));
                key.currentState.showSnackBar(SnackBar(
                  content: Text("Copied!"),
                ));
              },
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    url,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShelterDescription(ShelterInformation shelter) {
    if (shelter == null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Shelter opted out of giving information :("),
      );
    }
    const linkStyle = TextStyle(
      fontFamily: "OpenSans",
      color: Colors.blue,
    );
    const normalStyle =
        TextStyle(fontFamily: 'OpenSans', color: kPetPrimaryText);
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
              child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "I am at ",
              style: normalStyle,
              children: <TextSpan>[
                TextSpan(
                  text: "${shelter.name}, "
                      "${shelter.location}",
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      String search = Uri.encodeComponent("${shelter.name}, "
                          "${shelter.location}");
                      String url = "geo:0,0?q=$search";
                      if (await canLaunch(url)) launch(url);
                    },
                ),
              ],
            ),
          )),
          shelter.phone == ""
              ? Text("No phone number available, go visit!")
              : RichText(
                  text: TextSpan(
                    text: "Go visit or call ",
                    children: <TextSpan>[
                      TextSpan(
                        text: shelter.phone,
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            String url = "tel://${shelter.phone}";
                            if (await canLaunch(url)) launch(url);
                          },
                      ),
                    ],
                    style: normalStyle,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAdoptInfo() {
    return Column(
      children: <Widget>[
        Text(
          "Adopt ${widget.pet.name}!",
          style: const TextStyle(
              fontFamily: "Raleway",
              fontSize: 23.0,
              fontWeight: FontWeight.bold),
        ),
        FutureBuilder(
          future: getShelterInformation(widget.pet.location),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return Text('Wait..');
              case ConnectionState.waiting:
                return Text('Loading shleter information...');
              default:
                if (snapshot.hasError)
                  return new Text(
                      'Couldn\'t get the information :( ${snapshot.error}');
                else
                  return _buildShelterDescription(snapshot.data);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLinkSection(List<String> urls, key) {
    if (urls.isEmpty) return SizedBox();
    return Column(
      children: <Widget>[
        Divider(),
        Text("Links found:"),
        _buildUrlTags(urls, key),
        Text("Long press link to copy",
            style: const TextStyle(color: Colors.grey, fontSize: 12.0))
      ],
    );
  }
}