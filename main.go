package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"

	pb "gitlab.com/kkowa/apps/crawler/idl/grpc/helloworld"
	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
)

type server struct {
	pb.UnimplementedGreeterServer
}

func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloResponse, error) {
	log.Printf("Received: %v", in.GetName())
	return &pb.HelloResponse{Message: "Hello, " + in.GetName()}, nil
}

func main() {
	// TODO: Manage config via Viper
	environment := os.Getenv("ENVIRONMENT")
	if len(environment) == 0 {
		environment = "local"
	}
	log.Printf("Running on environment '%s'", environment)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", 50051))
	if err != nil {
		log.Fatalf("Failed to listen at :50051: %v", err)
	}
	s := grpc.NewServer()
	grpc_health_v1.RegisterHealthServer(s, health.NewServer())
	pb.RegisterGreeterServer(s, &server{})
	log.Printf("Server listening at %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
