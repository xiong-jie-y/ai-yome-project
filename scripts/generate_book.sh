set -e
cat docs/oss_perception/**/*.md > articles/oss-perception.md
md2review articles/oss-perception.md > ./review_configs/review_configs.re
cd ./review_configs/
rake pdf