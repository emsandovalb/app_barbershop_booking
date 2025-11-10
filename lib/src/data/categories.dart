class AppCategory {
  final String title;
  final String asset;
  const AppCategory(this.title, this.asset);
}

class AppCategories {
  // File names mapped to existing assets under assets/categories/
  static const list = <AppCategory>[
    AppCategory('Football', 'assets/categories/soccerBall.png'),
    AppCategory('Tennis', 'assets/categories/tennisBall.png'),
    AppCategory('Basketball', 'assets/categories/basketBall.png'),
    AppCategory('Volleyball', 'assets/categories/volleyball.png'),
    AppCategory('Baseball', 'assets/categories/baseball.png'),
    AppCategory('Padel', 'assets/categories/padel.png'),
  ];
}
