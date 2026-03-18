from __future__ import print_function

from unittest import TestCase

from universalmutator import mutator


class TestTolkRules(TestCase):
    def test_tolk_specific_regex_rules_generate_expected_mutants(self):
        source = [
            "struct (0x12345678) CounterIncrement {\n",
            "    incBy: uint32\n",
            "}\n",
            "fun CounterIncrement.bump(mutate self): self {\n",
            "    return self;\n",
            "}\n",
            "get fun currentCounter(): int {\n",
            "    return 0;\n",
            "}\n",
            "fun classify(value: CounterIncrement | null, body: slice) {\n",
            "    val msg = lazy AllowedMessage.fromSlice(body);\n",
            "    if (value is CounterIncrement) {\n",
            "        var noBounce = BounceMode.NoBounce;\n",
            "        var rich = BounceMode.RichBounce;\n",
            "        var root = BounceMode.RichBounceOnlyRootCell;\n",
            "        var shortBody = BounceMode.Only256BitsOfBody;\n",
            "    }\n",
            "    if (value !is CounterIncrement) {\n",
            "        return;\n",
            "    }\n",
            "}\n",
            "fun onBouncedMessage(in: InMessageBounced) {\n",
            "}\n",
            "fun onInternalMessage(in: InMessage) {\n",
            "}\n",
        ]

        mutants = mutator.mutants_regexp(
            source,
            ruleFiles=["tolk.rules"],
            ignorePatterns=[],
        )
        mutant_lines = {mutant[1].rstrip() for mutant in mutants}

        self.assertIn("struct (0x00000000) CounterIncrement {", mutant_lines)
        self.assertIn("struct (0xFFFFFFFF) CounterIncrement {", mutant_lines)
        self.assertIn("fun CounterIncrement.bump(self): self {", mutant_lines)
        self.assertIn("fun currentCounter(): int {", mutant_lines)
        self.assertIn("    var msg = lazy AllowedMessage.fromSlice(body);", mutant_lines)
        self.assertIn("    val msg = AllowedMessage.fromSlice(body);", mutant_lines)
        self.assertIn("    if (value !is CounterIncrement) {", mutant_lines)
        self.assertIn("    if (value is CounterIncrement) {", mutant_lines)
        self.assertIn("        var noBounce = BounceMode.RichBounce;", mutant_lines)
        self.assertIn("        var rich = BounceMode.NoBounce;", mutant_lines)
        self.assertIn("        var root = BounceMode.RichBounce;", mutant_lines)
        self.assertIn("        var shortBody = BounceMode.RichBounce;", mutant_lines)
        self.assertIn("fun onBouncedMessage(in: InMessage) {", mutant_lines)
        self.assertIn("fun onInternalMessage(in: InMessageBounced) {", mutant_lines)
