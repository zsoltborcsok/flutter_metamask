import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:metamask_messenger/utils/firestore_util.dart';

// No full text search - https://medium.com/@ken11zer01/firebase-firestore-text-search-and-pagination-91a0df8131ef
class UserSearch extends SearchDelegate<DocumentSnapshot> {
  final String _currentUserId;

  UserSearch(this._currentUserId);

  @override
  ThemeData appBarTheme(BuildContext context) {
    // https://github.com/flutter/flutter/issues/19734 - guojiex commented on Jan 17 2019
    ThemeData theme = Theme.of(context);
    return theme.copyWith(
        inputDecorationTheme: InputDecorationTheme(hintStyle: TextStyle(color: theme.primaryTextTheme.title.color)),
        primaryColor: theme.primaryColor,
        primaryIconTheme: theme.primaryIconTheme,
        primaryColorBrightness: theme.primaryColorBrightness,
        primaryTextTheme: theme.primaryTextTheme,
        textTheme: theme.textTheme
            .copyWith(headline6: theme.textTheme.headline6.copyWith(color: theme.primaryTextTheme.headline6.color)));
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    Stream<QuerySnapshot> querySnapshot = 0 < query.length
        ? firestore()
            .collection('users')
            .orderBy('name')
            .startAt(fieldValues: [query])
            .endAt(fieldValues: [query + '\uf8ff'])
            .limit(50)
            .onSnapshot
        : firestore().collection('users').orderBy('name').limit(50).onSnapshot;

    return StreamBuilder(
      stream: querySnapshot,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(child: CircularProgressIndicator()),
            ],
          );
        } else if (snapshot.data.docs.length == 0) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  'No Results Found.',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          );
        } else {
          var results = snapshot.data.docs;
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              var result = results[index];
              return ListTile(
                title: Text(result.get('name')),
                subtitle: Text(unEscape(result.id)),
                enabled: result.id != _currentUserId,
                onTap: () {
                  close(context, result);
                },
              );
            },
          );
        }
      },
    );
  }
}
