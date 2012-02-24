# Note that these options should probably be configurable per environment
# (prod may need different settings).
export CATALINA_OPTS=" \
-Xms256M \
-Xmx512M \
-XX:+UseConcMarkSweepGC \
-XX:+CMSPermGenSweepingEnabled \
-XX:+CMSClassUnloadingEnabled \
-XX:MaxPermSize=256M \
"
