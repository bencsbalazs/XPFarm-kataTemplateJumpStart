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

# -------------------------
# --- Initializing jest ---
# -------------------------

npm i jest --save-dev
node > _package.json << EOF
const package = require('./package.json');
package.scripts.test = 'jest --coverage';
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

# -----------------------------------------
# --- Initializing complexity reporting ---
# -----------------------------------------

npm i complexity-report --save-dev

node > _package.json << EOF
const package = require('./package.json');
package.scripts.complexity = 'cr src';
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

cat << EOF > .git/hooks/pre-commit
#!/bin/bash
echo "Generating complexity report..."
./generate-complexity-report
git add complexity-report.md
EOF
chmod a+x .git/hooks/pre-commit
git add .git/hooks/pre-commit
git update-index --chmod=+x .git/hooks/pre-commit

# -----------------------------
# --- Generate source files ---
# -----------------------------

mkdir src
cat > src/"$now-$packagename".js <<EOL
const ${packagename} = ()=>{

};

module.exports = { ${packagename} };
EOL
mkdir __tests__
cat > __tests__/"$now-$packagename".test.js <<EOL
const { expect } = require('chai');
const { ${packagename} } = require('../src/${now}-${packagename}.js');

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

cat > TechDebt.md <<EOL
# Technical debt
EOL

cat > notes.md <<EOL
# Notes

> Pomodoro 1

- Note

> Pomodoro 2

- Note
> Pomodoro 3

- Note
> Pomodoro 4

- Note
EOL

git add .
git commit -m "initialized repo with node & jest"
