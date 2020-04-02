import argparse
import ldap
import sys

# Setup the argument parser
parser = argparse.ArgumentParser()
parser.add_argument("-u", "--username", help="Username", required=True)
parser.add_argument("-p", "--password", help="Password", required=False)
args = parser.parse_args()

# Initialize our LDAP connection
conn = ldap.initialize("ldap://fs0.medianet")

try:
    # Attempt to use the credentials given
    conn.bind_s(f"uid={args.username},ou=People,dc=media,dc=warwicksu,dc=com",
                args.password, ldap.AUTH_SIMPLE)
    print("VALID")
    sys.exit(0)
except ldap.INVALID_CREDENTIALS:
    print("INCORRECT CREDENTIALS")
except ldap.SERVER_DOWN:
    print("CAN'T CONNECT TO SERVER")
except Exception:
    print("UNKOWN ERROR")

sys.exit(1)
