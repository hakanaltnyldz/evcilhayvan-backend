import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  getRecords,
  addRecord,
  updateRecord,
  deleteRecord,
  getWeightChart,
} from "../controllers/healthController.js";

const router = Router();
router.use(authRequired);

router.get("/:petId", getRecords);
router.post("/:petId", addRecord);
router.get("/:petId/weight-chart", getWeightChart);
router.put("/record/:id", updateRecord);
router.delete("/record/:id", deleteRecord);

export default router;
