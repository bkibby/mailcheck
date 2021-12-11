//
// mailcheck.c - Use with plesk to eliminate mails arriving which cannot be delivered
// (c) 2004 Bill Kibby <bill@bkibby.com> All rights reserved, etc.
//

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <mysql/mysql.h>

int mailcheck(char *email)
{
  MYSQL mysql;
  MYSQL_ROW row;
  MYSQL_RES *res;
  unsigned long numRows = 0;
  char buffer[120];
  char *pUname;
  char *pDname;
  char pQuery[800];
  int count;

//   sprintf(buffer,"%s\0",email);
  sprintf(buffer,"%s",email);
  pUname = strtok (buffer,"@");
  pDname = strtok (NULL,"@");

  strcpy(pQuery,"SELECT * FROM vpopmail, valias ");
  strcat(pQuery,"WHERE vpopmail.pw_name=\'");
  strcat(pQuery,pUname);
  strcat(pQuery,"\' OR valias.alias = \'");
  strcat(pQuery,pUname);
//  strcat(pQuery,"\'\0");

  /* Look at 31 - mysql_options() to read from my.cnf */

  mysql_init(&mysql);

  // Check to see if domain has catchall section...

  // Connect & query - Error handling...
  if(!mysql_real_connect(&mysql,"localhost","dbuser","dbpass","vpopmail",0,NULL,0)){
    printf("\n%s\n",mysql_error(&mysql));
    mysql_close(&mysql);
    return 1;
  }
  if( mysql_real_query(&mysql,pQuery,strlen(pQuery)) ){
    printf("\n%s\n",mysql_error(&mysql));
    mysql_close(&mysql);
    return 1;
  }
  if( !(res = mysql_store_result(&mysql)) ){
    printf("\n%s\n",mysql_error(&mysql));
    mysql_close(&mysql);
    return 1;
  }

  // If we have more than zero rows, user & domain match
  numRows = mysql_num_rows(res);
  if(numRows)
    row = mysql_fetch_row(res);
  else
  {
    mysql_free_result(res);
    mysql_close(&mysql);
    return 2;
  }

  // life is grand - let the mail in
  mysql_close(&mysql);
  return 0;
}

int main(int argc, char *argv[])
{  // mailcheck returns 0 on okay, 1 on db_error, 2 on invalid user, 3 on domain locked
  int mchk = 0;

//  printf("MySQL C Client Version: %s\n",mysql_get_client_info());

  if(argc<2) {
    printf("Invalid Search String\n");
    exit(2);
  }

  mchk = mailcheck(argv[1]);
  if(!mchk) {
    printf("Valid User\n");
  }
  else
  {
    // switch(
    printf("User unknown\n");
    exit(1);
  }

  exit(0);
}
