// Import and register all your controllers
import { application } from "./application"

// Import all controller files
import HelloController from "./hello_controller"

// Register controllers
application.register("hello", HelloController)
