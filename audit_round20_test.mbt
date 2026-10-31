///|
test "additional round 20: metagrammar syntax differential for independently mutated sources" {
  let meta = @moonabnf.compile(
    b"rulelist = 1*(rule / (*c-wsp c-nl))\r\nrule = rulename defined-as elements c-nl\r\nrulename = ALPHA *(ALPHA / DIGIT / \"-\")\r\ndefined-as = *c-wsp (\"=\" / \"=/\") *c-wsp\r\nelements = alternation *c-wsp\r\nc-wsp = WSP / (c-nl WSP)\r\nc-nl = comment / CRLF\r\ncomment = \";\" *(WSP / VCHAR) CRLF\r\nalternation = concatenation *(*c-wsp \"/\" *c-wsp concatenation)\r\nconcatenation = repetition *(1*c-wsp repetition)\r\nrepetition = [repeat] element\r\nrepeat = 1*DIGIT / (*DIGIT \"*\" *DIGIT)\r\nelement = rulename / group / option / char-val / num-val / prose-val\r\ngroup = \"(\" *c-wsp alternation *c-wsp \")\"\r\noption = \"[\" *c-wsp alternation *c-wsp \"]\"\r\nchar-val = [\"%i\"] quoted / \"%s\" quoted\r\nquoted = DQUOTE *(%x20-21 / %x23-7E) DQUOTE\r\nnum-val = \"%\" (bin-val / dec-val / hex-val)\r\nbin-val = \"b\" 1*BIT [1*(\".\" 1*BIT) / (\"-\" 1*BIT)]\r\ndec-val = \"d\" 1*DIGIT [1*(\".\" 1*DIGIT) / (\"-\" 1*DIGIT)]\r\nhex-val = \"x\" 1*HEXDIG [1*(\".\" 1*HEXDIG) / (\"-\" 1*HEXDIG)]\r\nprose-val = \"<\" *(%x20-3D / %x3F-7E) \">\"\r\n",
  ).unwrap()
  for
    source in [
      b"\n = \"a\"\r\n", b"\" = *[\"a\"] / (foo \"b\")\r\n", b"\"c\r\ns = %s\"a\"\r\n",
      b";c\r\ns \n= %s\"a\"\r\n", b";c\r\ns / %s\"a\"\r\n", b";c\r\ns = %\ns\"a\"\r\n",
      b";c\r\ns = %\"s\"a\"\r\n", b";c\r\ns = %%s\"a\"\r\n", b";c\r\ns = %s\"a\"\r\n",
      b";c\r\ns = %s\"a\"\rx", b";c\r\ns = %s\"a\"x\r\n", b";c\r\ns = %s\"a;\r\n",
      b";c\r\ns = %s\"a]\"\r\n", b";c\r\ns = %s]a\"\r\n", b";c\r\ns = %sa\"\r\n",
      b";c\r\ns =\" %s\"a\"\r\n", b";c\r\ns x= %s\"a\"\r\n", b";c\r\nsx= %s\"a\"\r\n",
      b";c%\ns = %s\"a\"\r\n", b";c(\ns = %s\"a\"\r\n", b";c;\r\ns = %s\"a\"\r\n",
      b";s = <p> ;c\r\n / \"b\"\r\n", b"s \"= \"a\"\r\n", b"s %= \"a\"\r\n", b"s ( \"a\"\r\n",
      b"s = \"a\"\r\n", b"s = \"a\"\r\n/", b"s = \"a\"\r\n;", b"s = \"a\"\rx", b"s = \"a\"\"\n",
      b"s = \"a\";\r\n", b"s = \"a;\r\n", b"s = \"p> ;c\r\n / \"b\"\r\n", b"s = \"xa\"\r\n",
      b"s = *[\"%a\"] / (foo \"b\")\r\n", b"s = *[\"(\"] / (foo \"b\")\r\n", b"s = *[\"a\"\"] / (foo \"b\")\r\n",
      b"s = *[\"a\"] / (]oo \"b\")\r\n", b"s = *[\"a\"] / (foo \"\")\r\n", b"s = *[\"a\"] / (foo \"b\"%)\r\n",
      b"s = *[\"a\"] / (foo \"b\")\r\n", b"s = *[\"a\"] / (foo \"b\")\r(\n", b"s = *[\"a\"] / (foo \"b\")\r;\n",
      b"s = *[\"a\"] / (foo \"b\")\r]", b"s = *[\"a\"] / (foo \"b\"/)\r\n", b"s = *[\"a\"] / (foo /\"b\")\r\n",
      b"s = *[\"a\"] / (foo ;\"b\")\r\n", b"s = *[\"a\"] / (foo ]b\")\r\n", b"s = *[\"a\"] / (foo( \"b\")\r\n",
      b"s = *[\"a\"] / /foo \"b\")\r\n", b"s = *[\"a\"] // (foo \"b\")\r\n", b"s = <p\n ;c\r\n / \"b\"\r\n",
      b"s = <p( ;c\r\n / \"b\"\r\n", b"s = <p> \n;c\r\n / \"b\"\r\n", b"s = <p> ;%\r\n / \"b\"\r\n",
      b"s = <p> ;%c\r\n / \"b\"\r\n", b"s = <p> ;c\r\n / \"%\"\r\n", b"s = <p> ;c\r\n / \"b\"\r\n",
      b"s = <p> ;c\r\n / \"b\"\r\n\"", b"s = <p> ;c\r\n / \"b\"\r]\n", b"s = <p> ;c\r\n / ;\"b\"\r\n",
      b"s = <p> ;c\r\n / xb\"\r\n", b"s = <p> ;c\r\n ]/ \"b\"\r\n", b"s = <p> ;c\r\n/ / \"b\"\r\n",
      b"s = <p> ;c\r\n// \"b\"\r\n", b"s = <p> ;c\r\nx/ \"b\"\r\n", b"s = <p> ;c\r\"\n / \"b\"\r\n",
      b"s = <p> ;c\r]\n / \"b\"\r\n", b"s = <p> ;c\rx\n / \"b\"\r\n", b"s = <p> ;c\rx / \"b\"\r\n",
      b"s = <p> ;c]\r\n / \"b\"\r\n", b"s = <p> ;xc\r\n / \"b\"\r\n", b"s = <p> ]c\r\n / \"b\"\r\n",
      b"s = <p>\";c\r\n / \"b\"\r\n", b"s = <p>;c\r\n / \"b\"\r\n", b"s =x\"a\"\r\n",
      b"s%= <p> ;c\r\n / \"b\"\r\n",
    ] {
    let a = @moonabnf.parse(source) is Ok(_)
    let r = meta.recognize("rulelist", source, limits={
      ..@moonabnf.default_match_limits(),
      max_work: 10000000,
      max_states: 1000000,
    })
    assert_true(r.status is @moonabnf.Matched || r.status is @moonabnf.NoMatch)
    assert_eq(a, r.status == @moonabnf.Matched)
  }
}
