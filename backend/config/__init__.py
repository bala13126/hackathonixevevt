import pymysql

pymysql.version_info = (2, 2, 1, "final", 0)
pymysql.__version__ = "2.2.1"
pymysql.install_as_MySQLdb()

try:
	from django.db.backends.mysql.features import DatabaseFeatures
	DatabaseFeatures.minimum_database_version = (10, 4)
except Exception:
	pass
