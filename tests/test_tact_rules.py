from __future__ import print_function

from unittest import TestCase

from universalmutator import mutator


class TestTactRules(TestCase):
    def test_tact_specific_regex_rules_generate_expected_mutants(self):
        source = [
            "fun main() {\n",
            "    a += 5;\n",
            "    b -= 6;\n",
            "    c *= 7;\n",
            "    d /= 8;\n",
            "    e &= 1;\n",
            "    f |= 2;\n",
            "    g ^= 3;\n",
            "    s <<= 1;\n",
            "    t >>= 1;\n",
            "    u << 2;\n",
            "    v >> 2;\n",
            "    var tval = true;\n",
            "    var fval = false;\n",
            "    var x = v ^ 1;\n",
            "    var y = v & 1;\n",
            "    var z = v | 1;\n",
            "    if (cond) {\n",
            "        break;\n",
            "    }\n",
            "    while (cond) {\n",
            "        continue;\n",
            "    }\n",
            "    until (cond) {\n",
            "    }\n",
            "    repeat (count) {\n",
            "    }\n",
            "    var q = cond ? a : b;\n",
            "    throwIf(cond);\n",
            "    throwUnless(cond);\n",
            "    doSomething();\n",
            "}\n",
        ]

        mutants = mutator.mutants_regexp(
            source,
            ruleFiles=["tact.rules"],
            ignorePatterns=[],
        )
        mutant_lines = {mutant[1].rstrip() for mutant in mutants}

        self.assertIn("    a -= 5;", mutant_lines)
        self.assertIn("    b += 6;", mutant_lines)
        self.assertIn("    e |= 1;", mutant_lines)
        self.assertIn("    f &= 2;", mutant_lines)
        self.assertIn("    s >>= 1;", mutant_lines)
        self.assertIn("    u >> 2;", mutant_lines)
        self.assertIn("    var tval = false;", mutant_lines)
        self.assertIn("    var fval = true;", mutant_lines)
        self.assertIn("    var x = v & 1;", mutant_lines)
        self.assertIn("    var y = v ^ 1;", mutant_lines)
        self.assertIn("        continue;", mutant_lines)
        self.assertIn("        break;", mutant_lines)
        self.assertIn("    while (0==1) {", mutant_lines)
        self.assertIn("    until (0==1) {", mutant_lines)
        self.assertIn("    repeat (0) {", mutant_lines)
        self.assertIn("    false ?  a  :  b;", mutant_lines)
        self.assertIn("    true ?  a  :  b;", mutant_lines)
        self.assertIn("    throwUnless(cond);", mutant_lines)
        self.assertIn("    throwIf(cond);", mutant_lines)
        self.assertIn("    throw(0);", mutant_lines)
