import { Router } from "express";
import { param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  getRecords,
  addRecord,
  updateRecord,
  deleteRecord,
  getWeightChart,
} from "../controllers/healthController.js";

const router = Router();
router.use(authRequired());

router.get("/:petId/weight-chart", [param("petId").isMongoId()], getWeightChart);
router.get("/:petId", [param("petId").isMongoId()], getRecords);
router.post("/:petId", [param("petId").isMongoId()], addRecord);
router.put("/record/:id", [param("id").isMongoId()], updateRecord);
router.delete("/record/:id", [param("id").isMongoId()], deleteRecord);

export default router;
