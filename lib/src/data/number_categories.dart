class NumberCategory {
  final String label;
  final String asset;
  const NumberCategory(this.label, this.asset);
}

class NumberCategories {
  static const list = <NumberCategory>[
    NumberCategory('5', 'assets/categories/numbers/image-5.png'),
    NumberCategory('7', 'assets/categories/numbers/image-7.png'),
    NumberCategory('11', 'assets/categories/numbers/image-11.png'),
  ];
}
