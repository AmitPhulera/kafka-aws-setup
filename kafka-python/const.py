GENERIC_KAFKA_CLIENT_ID = 'cchq-kafka-client'

DOMAIN = 'domain'
META = 'meta'
APP = 'app'
CASE_SQL = 'case-sql'
FORM_SQL = 'form-sql'
SMS = 'sms'
LEDGER = 'ledger'
COMMCARE_USER = 'commcare-user'
GROUP = 'group'
WEB_USER = 'web-user'
LOCATION = 'location'
SYNCLOG_SQL = 'synclog-sql'


CASE_TOPICS = (CASE_SQL, )
FORM_TOPICS = (FORM_SQL, )
USER_TOPICS = (COMMCARE_USER, WEB_USER)
ALL_TOPICS = (
    CASE_SQL,
    COMMCARE_USER,
    DOMAIN,
    FORM_SQL,
    GROUP,
    LEDGER,
    META,
    SMS,
    WEB_USER,
    APP,
    LOCATION,
    SYNCLOG_SQL,
)

KAFKA_BROKERS = ['10.203.40.211', '10.203.41.91', '10.203.42.247']