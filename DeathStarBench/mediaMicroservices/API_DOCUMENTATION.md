# Media Microservices API Documentation

This directory contains the Swagger/OpenAPI documentation for the Media Microservices application.

## Files

- `swagger.yaml` - OpenAPI 3.0 specification in YAML format
- `swagger.json` - OpenAPI 3.0 specification in JSON format (generated)

## Viewing the Documentation

### Option 1: Swagger UI (Recommended)

1. Install Swagger UI:
   ```bash
   docker run -p 8081:8080 -e SWAGGER_JSON=/swagger.yaml -v $(pwd):/usr/share/nginx/html/swagger -d swaggerapi/swagger-ui
   ```
   Then access: http://localhost:8081

2. Or use the online Swagger Editor:
   - Go to https://editor.swagger.io/
   - Copy and paste the contents of `swagger.yaml`

### Option 2: Redoc

```bash
npx @redocly/cli preview-docs swagger.yaml
```

### Option 3: Postman

1. Open Postman
2. Import → File → Select `swagger.yaml`
3. All endpoints will be imported as a collection

## API Endpoints

The Media Microservices API provides the following endpoints:

### User Management
- **POST** `/wrk2-api/user/register` - Register a new user

### Movie Management
- **POST** `/wrk2-api/movie/register` - Register a new movie
- **POST** `/wrk2-api/movie-info/write` - Write comprehensive movie information

### Review Management
- **POST** `/wrk2-api/review/compose` - Compose a review for a movie

### Content Management
- **POST** `/wrk2-api/cast-info/write` - Write cast information
- **POST** `/wrk2-api/plot/write` - Write plot information

## Base URL

- Local development: `http://localhost:8080`
- Docker container: `http://nginx-thrift:8080`

## Authentication

Currently, the API does not require authentication tokens. User authentication is handled through username/password in the request body for review composition.

## Request Formats

- Most endpoints accept `application/x-www-form-urlencoded` format
- Movie info, cast info, and plot endpoints accept `application/json` format

## Response Formats

All endpoints return plain text responses indicating success or error messages.

## Error Codes

The API may return the following HTTP status codes:

- `200` - Success
- `400` - Bad Request (incomplete or invalid arguments)
- `500` - Internal Server Error

## Example Usage

### Register a User

```bash
curl -X POST http://localhost:8080/wrk2-api/user/register \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "first_name=John&last_name=Doe&username=johndoe&password=securepass123"
```

### Register a Movie

```bash
curl -X POST http://localhost:8080/wrk2-api/movie/register \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "title=The Matrix&movie_id=tt0133093"
```

### Compose a Review

```bash
curl -X POST http://localhost:8080/wrk2-api/review/compose \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=johndoe&password=securepass123&title=The Matrix&rating=8&text=Great movie!"
```

### Write Movie Information

```bash
curl -X POST http://localhost:8080/wrk2-api/movie-info/write \
  -H "Content-Type: application/json" \
  -d '{
    "movie_id": "tt0133093",
    "title": "The Matrix",
    "casts": [
      {
        "cast_id": 1,
        "character": "Neo",
        "cast_info_id": 1001
      }
    ],
    "plot_id": 2001,
    "thumbnail_ids": ["thumb1"],
    "photo_ids": ["photo1"],
    "video_ids": ["video1"],
    "avg_rating": 8.7,
    "num_rating": 1500
  }'
```

## Microservices Architecture

The Media Microservices application consists of the following backend services:

- **UniqueIdService** - Generates unique IDs
- **MovieIdService** - Manages movie IDs
- **TextService** - Handles text content
- **RatingService** - Manages ratings
- **UserService** - User management
- **ComposeReviewService** - Orchestrates review composition
- **ReviewStorageService** - Stores reviews
- **MovieReviewService** - Manages movie reviews
- **UserReviewService** - Manages user reviews
- **CastInfoService** - Manages cast information
- **PlotService** - Manages plot information
- **MovieInfoService** - Manages movie information
- **PageService** - Aggregates page data

These services communicate via Thrift RPC and are orchestrated through the Nginx web server.

## Tracing

The application uses OpenTracing with Jaeger for distributed tracing. You can view traces at:

- Jaeger UI: http://localhost:16686

## Additional Resources

- [OpenAPI Specification](https://swagger.io/specification/)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [DeathStarBench Documentation](../README.md)

