/* udpclient.c */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <queue>
#include <fstream>
#include <iostream>
#include <cstring>
#include <map>
#include <unordered_map>
#include <string>
#include <cstdlib>
#include <cstdio>
#include <cmath>
#include <algorithm>
#include <list>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/time.h>
#include <string>
#include <sstream>
#include <mutex>
#include <vector>


using namespace std;
struct timeval cur_time;

int id, hi = 1, lsai = 5, spfi = 20, c, a_arg, b_arg, c_arg, d_arg ;
string infile, outfile;
int n_routers, n_edges;
struct sockaddr_in server_addr;
ifstream inp;
ofstream oup;

mutex mtx1;
mutex mtx2;

class Router{
	
	public:
		int id, cur_lsa;
		map<int, pair<int, int> > neigh;
		int udp_soc, sock;
		struct sockaddr_in server_addr, client_addr;
	    struct hostent *host;
	    unordered_map<int, int> latest_seq;
	    map<int, map<int, int> > adj_list;
	    map<int, int> time_mon;
   	
		Router()
		{
			id = 0;
			cur_lsa = 1000;
		}
		Router(int id_this)
		{
			id = id_this;
			cur_lsa = 1000;
			udp_soc = 20000 + id;
		}	
			
		void setup_socket()
		{
			host = (struct hostent *) gethostbyname("localhost");

			if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
				perror("Socket");
				exit(1);
			}

			server_addr.sin_family = AF_INET;
			server_addr.sin_port = htons(udp_soc);
			server_addr.sin_addr = *((struct in_addr *) host->h_addr);
			bzero(&(server_addr.sin_zero), 8);

			if (::bind(sock, (struct sockaddr *) &server_addr, sizeof (struct sockaddr)) == -1) {
				perror("Bind");
				exit(1);
			}

		}	
};

void set_receiver(int port, string ip)
{
	struct hostent *host ;
	host = (struct hostent *) gethostbyname(ip.c_str());

	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(port);
	server_addr.sin_addr = *((struct in_addr *) host->h_addr);
	bzero(&(server_addr.sin_zero), 8);
}

std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}

Router router_map;

void *send_hello(void *useless)
{
	while(1)
	{
		sleep(hi);
	//	cout << "sayHello" << endl;
		
    	string send_data = "HELLO";
    	send_data += " " + to_string(id);

		for(map<int,pair<int, int> >::iterator i = router_map.neigh.begin(); i != router_map.neigh.end(); i++)
		{	
			set_receiver(20058, "node-" + to_string(i->first));
		//	cout << "SENT : " << send_data << " " << i->first << endl;
			gettimeofday(&cur_time, NULL);
			int gen_time=(cur_time.tv_sec+(cur_time.tv_usec/1000000))%10000;

			router_map.time_mon[i->first] = gen_time;
       		sendto(router_map.sock, send_data.c_str(), send_data.size(), 0, (struct sockaddr *) &(server_addr), sizeof (struct sockaddr));	
       	}	
         
	}
}

void *send_lsa(void *useless)
{
	while(1)
	{
		sleep(lsai);
		cout << "sendLAS" << endl;
		
    	string send_data = "LSA";
    	send_data += " " + to_string(id);
    	send_data += + " " + to_string(router_map.cur_lsa++);	//update cur_las by 1
    	send_data += + " " + to_string(router_map.neigh.size());
    	
		for(map< int, int>::iterator i = router_map.adj_list[id].begin(); i != router_map.adj_list[id].end(); i++)
		{	
       		send_data += " " + to_string(i->first);
       		send_data += " " + to_string(i->second);

       		cout << i->first << " " << i->second << endl;
       	}	

    //   	cout << "LSA PACKET : " << send_data << endl;

       	for(map<int,pair<int, int> >::iterator i = router_map.neigh.begin(); i != router_map.neigh.end(); i++)
		{	
			set_receiver(20058, "node-" + to_string(i->first));
			sendto(router_map.sock, send_data.c_str(), send_data.size(), 0, (struct sockaddr *) &(server_addr), sizeof (struct sockaddr));	
       	}	
	}
}

void forward_lsa(string packet)
{
	//TODO
	vector<string> token;
	token = split(packet, ' ', token);

	if((router_map.latest_seq[stoi(token[1])] == 0) || (router_map.latest_seq[stoi(token[1])] > stoi(token[2]) ) )
	{
		for(map<int,pair<int, int> >::iterator i = router_map.neigh.begin(); i != router_map.neigh.end(); i++)
		{	
			if(stoi(token[1]) != i->first)
			{
				set_receiver(20058, "node-" + to_string(i->first));
				sendto(router_map.sock, packet.c_str(), packet.size(), 0, (struct sockaddr *) &(server_addr), sizeof (struct sockaddr));	
    	   		cout << "FOrwarding : " << token[1] << " " <<   i->first << endl;
       		}
       	}
       	router_map.latest_seq[stoi(token[1])] = stoi(token[2]);
	}
}

class Prioritize
{
public:
    int operator() ( const pair<int, int>& p1, const pair<int, int>& p2 )
    {
        return p1.second < p2.second;
    }
};

void *run_djikstra(void *useless)
{
	sleep(5);
	while(1)
	{
		sleep(spfi);
		//cout << "Running djikstra" << endl;
	
		vector<int> dist(n_routers, 100000);
		vector<int> previous(n_routers, -1);
		dist[id] = 0;
		priority_queue<pair<int, int>, vector<pair<int, int> >, Prioritize > qu;
		
		qu.push(pair<int, int>(id, 0));

		mtx1.lock();
		cout << "Adjacency Matrix : \n";
		for(int p = 0; p < n_routers; p++)
		{
			for(int q = 0; q < n_routers; q++)
				cout << router_map.adj_list[p][q] << " ";
			cout << endl;
		}	
		mtx1.unlock();	
		
		while(!qu.empty())
		{
			pair<int, int> top = qu.top();
			qu.pop();

			int u = top.first;
			if(top.second <= dist[u])
			for(map<int, int>::iterator it = router_map.adj_list[u].begin(); it != router_map.adj_list[u].end(); it++)	
			{
				if((router_map.adj_list[u][it->first] != 0) && (dist[u] + router_map.adj_list[u][it->first] < dist[it->first]))
				{
					cout << " **** in djikstra *** "<< u << " " << dist[u] << endl;
					dist[it->first] = dist[u] + router_map.adj_list[u][it->first];	
					previous[it->first] = u;
					qu.push(pair<int, int>(it->first, dist[it->first]));
				}	
			}

		}

		mtx2.lock();
		oup << "------------------\n";
		gettimeofday(&cur_time, NULL);
		double start_time=cur_time.tv_sec%1000000 ;
		cout << start_time << endl;
		oup << "Table for " << id << " at time " << start_time << endl;
		for(int p = 0; p < n_routers; p++)
		{
			oup << p << " | " ;
			if(p!=id)
				for(int vertex = p ;vertex != id; vertex = previous[vertex])
					oup << vertex << " -> " ;
				oup << id;
			oup << " | " <<  dist[p] << endl;
			// print the table here
		}
		oup << "------------------\n";
		mtx2.unlock();
	}
}

int find_type(string s)
{
	int spaces = count_if(s.begin(), s.end(), [](unsigned char c){ return std::isspace(c); });

	if(spaces == 1)
		return 1;
	else if(spaces == 3)
		return 2;
	else
		return 3;			
}

int main(int argc, char *argv[]) 
{

	struct sockaddr_in client_addr;
	opterr = 0;
	while ((c = getopt (argc, argv, "i:f:o:h:a:s:")) != -1)
	{
		switch (c)
		{
			case 'i' :{ id = atoi(optarg);break;}
			case 'f' :{ infile = optarg;break;}
			case 'o' :{ outfile = optarg;break;}
			case 'h' :{ hi = atoi(optarg); break;}
			case 'a' :{ lsai = atoi(optarg);break;}
			case 's' :{ spfi = atoi(optarg);break;}
			default:
				abort ();
		}
	}
	
	cout << id << infile << outfile << hi << lsai << spfi;   
	
	inp.open(infile.c_str());
	oup.open(outfile.c_str());
	
	inp >> n_routers >> n_edges;
	cout << endl<< n_routers << n_edges << endl;
	
	// Setting up the router information
	router_map = Router(id);
	
	while(inp >> a_arg >> b_arg >> c_arg >> d_arg)
	{
		if(a_arg == id)
			router_map.neigh[b_arg] = pair<int,int>(c_arg, d_arg);
		if(b_arg == id)
			router_map.neigh[a_arg] = pair<int,int>(c_arg, d_arg);
	//	cout << "...." <<  a_arg << " " << b_arg << endl;
	}
	
	router_map.setup_socket();

	pthread_t thread1, thread2, thread3, thread4;
	int iret1, iret2, iret3, iret4;
	int lki = 2;

	iret1 = pthread_create( &thread1, NULL, send_hello, (void *)lki);
    if(iret1)
    {
        fprintf(stderr,"Error - pthread_create() return code: %d\n",iret1);
        exit(EXIT_FAILURE);
    }

 	iret2 = pthread_create( &thread2, NULL, run_djikstra, (void *)lki);
    if(iret2)
    {
        fprintf(stderr,"Error - pthread_create() return code: %d\n",iret1);
        exit(EXIT_FAILURE);
    }
    
    iret3 = pthread_create( &thread3, NULL, send_lsa, (void *)lki);
    if(iret1)
    {
        fprintf(stderr,"Error - pthread_create() return code: %d\n",iret1);
        exit(EXIT_FAILURE);
    }
    
    iret4 = pthread_create( &thread4, NULL, run_djikstra, (void *)lki);
    if(iret1)
    {
        fprintf(stderr,"Error - pthread_create() return code: %d\n",iret1);
        exit(EXIT_FAILURE);
    }

    //cout << "FIND TYPE " << find_type("Hi Im") << endl;

    /*************************/

    while(1)
	{
		
		unsigned int addr_len = sizeof (struct sockaddr);
		fflush(stdout);
		char recv_data[1024];
		
		int bytes_read = recvfrom(router_map.sock, recv_data, 1024, MSG_DONTWAIT, (struct sockaddr *) &(client_addr), &addr_len);
		if(bytes_read > 0)	
		{
			recv_data[bytes_read] = '\0';
			int type = find_type(recv_data);

			if(type == 1) // HELLO packet
			{
			//	cout << "RECEIVED : " << recv_data <<"\n";
				string send_data;	
				vector<string> token;
    			token = split(recv_data, ' ', token);	
				int rad = rand()%( router_map.neigh[stoi(token[1])].second - router_map.neigh[stoi(token[1])].first ) + router_map.neigh[stoi(token[1])].first;
				send_data = "HELLOREPLY " + to_string(id) + " " + token[1] + " "+ to_string(rad);
			//	cout << send_data << endl;
				sendto(router_map.sock, send_data.c_str(), send_data.size(), 0, (struct sockaddr *) &(client_addr), sizeof (struct sockaddr));
    		}
    		else if(type == 2)	// HELLO REPLY packet
    		{
    			cout << "UPDATE : " << recv_data << endl;
				gettimeofday(&cur_time, NULL);
				int gen_time=(cur_time.tv_sec+(cur_time.tv_usec/1000000))%10000;

				
    			vector<string> token;
    			token = split(recv_data, ' ', token);
    			
    				cout  << "...." << gen_time << " " << gen_time - router_map.time_mon[atoi(token[2].c_str())]<< endl;
    			router_map.adj_list[atoi(token[2].c_str())][atoi(token[1].c_str())] = gen_time - router_map.time_mon[atoi(token[1].c_str())];
    			router_map.adj_list[atoi(token[1].c_str())][atoi(token[2].c_str())] = gen_time - router_map.time_mon[atoi(token[1].c_str())];
    		//	cout << "TOKENS : " << stoi(token[1]) << " " << stoi(token[2]) << " "<< stoi(token[3]) << "\n";
			
       		}
       		else if(type == 3)	// LSA packet
       		{
       			//Update adjacency list

       			vector<string> token;
       			token = split(recv_data, ' ', token);
       			
       			for(int i = 0, j = 4; i < stoi(token[3]); i++, j+=2)
        		{
        			router_map.adj_list[stoi(token[j])][stoi(token[1])] = stoi(token[j+1]) ;
        			router_map.adj_list[stoi(token[1])][stoi(token[j])] = stoi(token[j+1]) ;
				}	

					//forward packet

       			forward_lsa(recv_data); 

       		}
		}
		fflush(stdout);
	}
    /*************************/
	 	 
	pthread_join( thread1, NULL);
    pthread_join( thread2, NULL);
    pthread_join( thread3, NULL);
    pthread_join( thread4, NULL);
    
}
