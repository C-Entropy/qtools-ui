#|
 This file is a part of Qtools-UI
 (c) 2015 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.qtools.ui)
(in-readtable :qtools)

(define-widget compass (QWidget layout)
  ((north :initform NIL)
   (east :initform NIL)
   (south :initform NIL)
   (west :initform NIL)
   (center :initform NIL)))

(defmethod initialize-instance :after ((compass compass) &key north east south west center &allow-other-keys)
  (when north (setf (widget :north compass) north))
  (when east (setf (widget :east compass) east))
  (when south (setf (widget :south compass) south))
  (when west (setf (widget :west compass) west))
  (when center (setf (widget :center compass) center)))

(defmethod widget ((place symbol) (compass compass))
  (with-slots-bound (compass compass)
    (ecase place
      (:north north)
      (:east east)
      (:south south)
      (:west west)
      (:center center))))

(defmethod (setf widget) (widget (place symbol) (compass compass))
  (with-slots-bound (compass compass)
    (macrolet ((setplace (symb to)
                 `(progn (when ,symb (setf (parent ,symb) NIL))
                         (setf ,symb ,to))))
      (ecase place
        (:north (setplace north widget))
        (:east (setplace east widget))
        (:south (setplace south widget))
        (:west (setplace west widget))
        (:center (setplace center widget)))))
  (when widget
    (setf (parent widget) compass))
  widget)

(defmethod (setf widget) ((widget qobject) (place qobject) (compass compass))
  (setf (widget (or (widget-position place compass)
                    (error "~a is not contained in ~a." widget compass))
                compass)
        widget))

(defmethod widget-position (widget (compass compass) &key key test test-not)
  (with-slots-bound (compass compass)
    (flet ((compare (field)
             (cond (test-not (not (funcall test-not (funcall key field) widget)))
                   (test (funcall test (funcall key field) widget)))))
      (cond ((compare north) :north)
            ((compare east) :east)
            ((compare south) :south)
            ((compare west) :west)
            ((compare center) :center)))))

(defmethod find-widget (widget (compass compass) &key key test test-not)
  (with-slots-bound (compass compass)
    (flet ((compare (field)
             (cond (test-not (not (funcall test-not (funcall key field) widget)))
                   (test (funcall test (funcall key field) widget)))))
      (cond ((compare north) north)
            ((compare east) east)
            ((compare south) south)
            ((compare west) west)
            ((compare center) center)))))

(defmethod widget-at-point ((point qobject) (compass compass))
  (with-slots-bound (compass compass)
    (flet ((compare (field)
             (and field (q+:contains (q+:geometry field) point))))
      (cond ((compare north) north)
            ((compare east) east)
            ((compare south) south)
            ((compare west) west)
            ((compare center) center)))))

(defmethod add-widget ((widget qobject) (compass compass))
  (setf (widget :center compass) widget))

(defmethod insert-widget ((widget qobject) (place symbol) (compass compass))
  (setf (widget place compass) widget))

(defmethod insert-widget ((widget qobject) (place qobject) (compass compass))
  (setf (widget (or (widget-position place compass)
                    (error "~a is not contained in ~a." place compass))
                compass)
        widget))

(defmethod remove-widget ((place symbol) (compass compass))
  (prog1 (widget place compass)
    (setf (widget place compass) NIL)))

(defmethod remove-widget ((widget qobject) (compass compass))
  (remove-widget (or (widget-position widget compass)
                     (error "~a is not contained in ~a." widget compass))
                 compass))

(defmethod clear-layout ((compass compass))
  (remove-widget (list :north :east :south :west :center) compass))

(defmethod swap-widgets (a b (compass compass))
  (with-slots-bound (compass compass)
    (let ((a (or (widget-position a compass)
                 (error "~a is not contained in ~a." a compass)))
          (b (or (widget-position b compass)
                 (error "~a is not contained in ~a." b compass))))
      (let ((wa (widget a compass))
            (wb (widget b compass)))
        (flet ((set-place (place widget)
                 (ecase place
                   (:north (setf north widget))
                   (:east (setf east widget))
                   (:south (setf south widget))
                   (:west (setf west widget))
                   (:center (setf center widget)))))
          (set-place a wa)
          (set-place b wb)
          compass)))))

(defmethod widget-acceptable-p ((null null) (compass compass))
  T)

(define-initializer (compass setup) ()
  (when north (setf (parent north) compass))
  (when east (setf (parent east) compass))
  (when south (setf (parent south) compass))
  (when west (setf (parent west) compass))
  (when center (setf (parent center) compass))
  (update compass))

(macrolet ((? (form &optional default)
             (let ((var (third form)))
               `(if (and ,var (q+:is-visible ,var))
                    ,form
                    ,(if default most-positive-fixnum 0))))
           (set-geometry (target x y w h)
             `(when (and ,target (q+:is-visible ,target))
                (let ((hint (q+:size-hint ,target)))
                  (declare (ignorable hint))
                  (setf (q+:geometry ,target) (values ,x ,y ,w ,h))))))

  (defmethod update ((compass compass))
    (with-slots-bound (compass compass)
      (set-geometry north
                    0 0
                    (q+:width compass) (q+:height hint))
      (set-geometry south
                    0 (- (q+:height compass) (q+:height north))
                    (q+:width compass) (q+:height hint))
      (set-geometry west
                    0 (? (q+:height north))
                    (q+:width hint) (- (q+:height compass) (? (q+:height north)) (? (q+:height south))))
      (set-geometry east
                    (- (q+:width compass) (q+:width east)) (? (q+:height north))
                    (q+:width hint) (- (q+:height compass) (? (q+:height north)) (? (q+:height south))))
      (set-geometry center
                    (? (q+:width west))
                    (? (q+:height north))
                    (- (q+:width compass) (? (q+:width west)) (? (q+:width east)))
                    (- (q+:height compass) (? (q+:height north)) (? (q+:height south))))))
  
  (define-override (compass minimum-height) ()
    (+ (? (q+:minimum-height north))
       (max (? (q+:minimum-height center))
            (? (q+:minimum-height east))
            (? (q+:minimum-height west)))
       (? (q+:minimum-height south))))

  (define-override (compass minimum-width) ()
    (max (? (q+:minimum-width north))
         (? (q+:minimum-width south))
         (+ (? (q+:minimum-width east))
            (? (q+:minimum-width center))
            (? (q+:minimum-width west)))))

  (define-override (compass maximum-height) ()
    (+ (? (q+:maximum-height north))
       (min (? (q+:maximum-height east) T)
            (? (q+:maximum-height center) T)
            (? (q+:maximum-height west) T)
            (if (or (and east (q+:is-visible east))
                    (and center (q+:is-visible center))
                    (and west (q+:is-visible west)))
                most-positive-fixnum 0))
       (? (q+:maximum-height south))))

  (define-override (compass maximum-width) ()
    (min (? (q+:maximum-width north) T)
         (? (q+:maximum-width south) T)
         (+ (? (q+:maximum-width east))
            (? (q+:maximum-width center))
            (? (q+:maximum-width west))
            (if (or (and east (q+:is-visible east))
                    (and center (q+:is-visible center))
                    (and west (q+:is-visible west)))
                0 most-positive-fixnum)))))
