import mongoose from "mongoose";
const { Schema } = mongoose;

const commentSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    userName: { type: String, required: true },
    userAvatar: { type: String },
    text: { type: String, required: true, maxlength: 500 },
  },
  { timestamps: true, toJSON: { transform(_doc, ret) { ret.id = ret._id; delete ret._id; return ret; } } }
);

const postSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    userName: { type: String, required: true },
    userAvatar: { type: String },
    content: { type: String, maxlength: 1000 },
    photos: { type: [String], default: [] },
    petId: { type: Schema.Types.ObjectId, ref: "Pet" },
    petName: { type: String },
    likes: { type: [Schema.Types.ObjectId], ref: "User", default: [] },
    comments: { type: [commentSchema], default: [] },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

postSchema.index({ userId: 1, createdAt: -1 });
postSchema.index({ createdAt: -1 });

export default mongoose.model("Post", postSchema);
