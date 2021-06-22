#!/bin/bash
[[ -z "$1" ]] && { echo 'No package name is given.'; exit 1; }
if [ -z "$2" ]; then
  now="$(date +'%Y-%m-%d')"
else
  now=$2
fi
packagename="$1"
git commit -m "initial commit" --allow-empty
npm init -y

# Initializing jest

npm i jest --save-dev
node > _package.json << EOF
const package = require('./package.json');
package.scripts.test = 'jest';
console.log(JSON.stringify(package, null, 2));
EOF
rm package.json
mv _package.json package.json

cat << EOF > test
#!/bin/bash
npm test -- --watchAll --collect-coverage
EOF
chmod a+x test
git add test
git update-index --chmod=+x test

# Initializing complexity reporting

npm i complexity-report --save-dev

node > _package.json << EOF
const package = require('./package.json');
package.scripts.complexity = 'cr src';
console.log(JSON.stringify(package, null, 2));
EOF
rm package.json
mv _package.json package.json

cat << EOF > .complexrc
{
  "output": "complexity-report.md",
  "format": "markdown",
  "allfiles": false,
  "ignoreerrors": true,
  "filepattern": "(.(?<!\\\\.test))\\\\.js$",
  "dirpattern": ".+",
  "maxfiles": 256,
  "maxcyc": 4,
  "silent": false,
  "logicalor": false,
  "switchcase": false,
  "forin": false,
  "trycatch": false,
  "newmi": false
}
EOF

cat << EOF > generate-complexity-report
#!/bin/bash
npm run complexity
EOF

chmod a+x generate-complexity-report
git add generate-complexity-report
git update-index --chmod=+x generate-complexity-report

cat << EOF > generate-metrics-report
#!/bin/bash
npm test -- --json --outputFile="test-report.json" --coverage --coverageReporters="json-summary"
npm run complexity -- -o complexity-report.json -f json

node << EOS > metrics.md
const marker = (success) => success ? '✅' : '❌';
const test = require('./test-report.json');
const coverage = require('./coverage/coverage-summary.json');
const complexity = require('./complexity-report.json');
const testResultMarker = marker(test.success);
let testResult;
if (test.success) {
  testResult = 'SUCCESS';
} else {
  testResult = 'FAILURE';
}
let coverageSuccess = true;

let coverageTable = '';
for (let type of ['lines','statements','functions','branches']) {
  const typeSummary = coverage.total[type];
  const total = typeSummary.total;
  const covered = typeSummary.covered;
  const skipped = typeSummary.skipped;
  const percentage = typeSummary.pct.toFixed(2);
  coverageSuccess &= percentage == 100;
  coverageTable += \\\`| \\\${type} | \\\${total} | \\\${covered} | \\\${skipped} | \\\${percentage}% |\\n\\\`;
}
const coverageMarker = marker(coverageSuccess);

const complexityMarker = marker(complexity.cyclomatic <= 4);

console.log(\\\`\\
# Repo Metrics\\n\\
## Tests \\\${testResultMarker}\\n\\
Result: \\\${testResult}\\n\\n\\
Failed tests: \\\${test.numFailedTests}\\n\\n\\
Passed tests: \\\${test.numPassedTests}\\n\\n\\
## Coverage \\\${coverageMarker}\\n\\
| Type | Total | Covered | Skipped | Percentage |\\n\\
|------|------:|--------:|--------:|------------|\\n\\
\\\${coverageTable}\\n\\
## Complexity \\\${complexityMarker}\\n\\
Cyclomatic complexity: \\\${complexity.cyclomatic}\\n\\n\\
[Full report](complexity-report.md)\\n\\n\\
\\n\\
\\\`);
EOS

rm test-report.json
rm complexity-report.json

EOF
chmod a+x generate-metrics-report
git add generate-metrics-report
git update-index --chmod=+x generate-metrics-report

cat << EOF > .git/hooks/pre-commit
#!/bin/bash
echo "Generating complexity report..."
./generate-complexity-report
git add complexity-report.md

echo "Generating metrics report..."
./generate-metrics-report
git add metrics.md

EOF
chmod a+x .git/hooks/pre-commit
git add .git/hooks/pre-commit
git update-index --chmod=+x .git/hooks/pre-commit

# Adding sample source files

mkdir src
cat > src/"$now-$packagename".js <<EOL
const ${packagename} = ()=>{

};

module.exports = { ${packagename} };
EOL

cat > packages/"$now-$packagename"/__tests__/"$now-$packagename".test.js <<EOL
const { expect } = require('chai');
const { ${packagename} } = require('../lib/${now}-${packagename}.js');

describe('Testing ${now}-${packagename}...', () => {
  describe('User story 1', ()=>{
    it('', ()=>{
      expect(${packagename}()).equal(true);
    });
    it.skip('', ()=>{

    });
  });

  describe('User story 2', ()=>{
    it.skip('', ()=>{

    });
    it.skip('', ()=>{

    });
  })
});
EOL

cat > README.md <<EOL
# ${now}-${packagename}

> TODO: description

## User story 1

> As a user, I have to know if the input is valid

- User test 1/1: It should be false if
- User test 1/2: It should be false if

## User story 2

> As a user, I have to know if returning the correct value

- User test 2/1: It should be false if
- User test 2/2: It should be false if
EOL

git add .
git commit -m "initialized repo with node & jest"
