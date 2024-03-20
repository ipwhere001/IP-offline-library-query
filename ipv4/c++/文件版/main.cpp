#include<iostream>
#include<string>
#include "ipDataCloud.h"

using namespace std;

int main() {
	system("chcp 65001");
	geo_ip* finder = ip_instance();
	char ip[] = "49.81.179.93";
	char* local = ip_query(finder, ip);
	cout << local << endl;
}
